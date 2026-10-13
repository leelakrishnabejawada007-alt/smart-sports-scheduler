import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// The only thing the app knows about authentication.
abstract class AuthService {
  /// Token of the signed-in user (null when signed out).
  String? get token;

  Future<AppUser> login({required String email, required String password});
  Future<AppUser> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  });

  /// Re-opens a saved session. Returns null if the token is no longer valid;
  /// throws if the server cannot be reached.
  Future<AppUser?> restore(String token);

  Future<void> logout();
}

/// In-memory accounts for demos and tests (passwords are NOT hashed here).
/// Seeded: demo@student.edu / Demo@1234, admin@sports.edu / Admin@1234.
class MockAuthService implements AuthService {
  MockAuthService({this.latency = const Duration(milliseconds: 700)}) {
    _add(const AppUser(
        id: 'u0', name: 'Demo Student', studentId: '2023001', email: 'demo@student.edu'),
        'Demo@1234');
    _add(const AppUser(
        id: 'u-admin',
        name: 'Admin',
        studentId: '9000001',
        email: 'admin@sports.edu',
        role: 'admin'),
        'Admin@1234');
  }

  final Duration latency;
  final List<AppUser> _users = [];
  final Map<String, String> _passwords = {}; // user id -> password
  int _counter = 0;
  String? _token;

  @override
  String? get token => _token;

  void _add(AppUser u, String password) {
    _users.add(u);
    _passwords[u.id] = password;
  }

  Future<void> _wait() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);

  @override
  Future<AppUser> login({required String email, required String password}) async {
    await _wait();
    final mail = email.trim().toLowerCase();
    for (final u in _users) {
      if (u.email.toLowerCase() == mail && _passwords[u.id] == password) {
        _token = 'mock-${u.id}';
        return u;
      }
    }
    throw const AuthException('Incorrect email or password.');
  }

  @override
  Future<AppUser> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) async {
    await _wait();
    final mail = email.trim().toLowerCase();
    if (_users.any((u) => u.email.toLowerCase() == mail)) {
      throw const AuthException('An account with this email already exists.');
    }
    if (_users.any((u) => u.studentId == studentId.trim())) {
      throw const AuthException('This student ID is already registered.');
    }
    final user = AppUser(
      id: 'u${++_counter}',
      name: name.trim(),
      studentId: studentId.trim(),
      email: mail,
    );
    _add(user, password);
    _token = 'mock-${user.id}';
    return user;
  }

  @override
  Future<AppUser?> restore(String token) async {
    await _wait();
    for (final u in _users) {
      if (token == 'mock-${u.id}') {
        _token = token;
        return u;
      }
    }
    return null;
  }

  @override
  Future<void> logout() async => _token = null;
}

/// Real REST client for backend/server.py:
///   POST /auth/login, POST /auth/register -> {token, user}
///   GET  /auth/me (Bearer token)          -> {user}
///   POST /auth/logout
/// 401 = bad credentials / expired session, 409 = account already exists.
class HttpAuthService implements AuthService {
  HttpAuthService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  String? token;

  String _message(http.Response res, String fallback) {
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {}
    return fallback;
  }

  Future<AppUser> _post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw AuthException(_message(res, 'Something went wrong. Please try again.'));
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    token = json['token'] as String?;
    return AppUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> login({required String email, required String password}) =>
      _post('/auth/login', {'email': email.trim(), 'password': password});

  @override
  Future<AppUser> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) =>
      _post('/auth/register', {
        'name': name.trim(),
        'studentId': studentId.trim(),
        'email': email.trim(),
        'password': password,
      });

  @override
  Future<AppUser?> restore(String saved) async {
    final res = await _client.get(Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $saved'});
    if (res.statusCode == 401) return null;
    if (res.statusCode != 200) throw Exception('Server error');
    token = saved;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return AppUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    final t = token;
    token = null;
    if (t == null) return;
    try {
      await _client.post(Uri.parse('$baseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer $t'});
    } catch (_) {}
  }
}
