import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';

/// Holds the signed-in user and keeps the login saved between app launches.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service, {SessionStore? store})
      : _store = store,
        _restoring = store != null;

  final AuthService _service;
  final SessionStore? _store;
  AppUser? _user;
  bool _busy = false;
  bool _restoring;
  String? _error;

  AppUser? get user => _user;
  bool get busy => _busy;

  /// True while a saved login is being re-opened at app start.
  bool get restoring => _restoring;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Called once at app start: skips the login page if a valid session is saved.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;
    try {
      final saved = await store.load();
      if (saved != null) {
        final user = await _service.restore(saved.token);
        if (user != null) {
          _user = user;
          await store.save(saved.token, user); // refresh cached profile
        } else {
          await store.clear(); // expired or revoked
        }
      }
    } catch (_) {
      // Server unreachable: show login, keep the saved session for next time.
    }
    _restoring = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) =>
      _run(() => _service.login(email: email, password: password));

  Future<bool> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) =>
      _run(() => _service.register(
          name: name, studentId: studentId, email: email, password: password));

  /// Login for the /admin page: rejects accounts that are not admins.
  Future<bool> adminLogin({required String email, required String password}) async {
    final ok = await login(email: email, password: password);
    if (ok && !isAdmin) {
      _service.logout();
      _store?.clear();
      _user = null;
      _error = 'This account does not have admin access.';
      notifyListeners();
      return false;
    }
    return ok;
  }

  void logout() {
    _user = null;
    _error = null;
    _service.logout();
    _store?.clear();
    notifyListeners();
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      final token = _service.token;
      if (token != null) await _store?.save(token, _user!);
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = AppConfig.useMock
          ? 'Something went wrong. Please try again.'
          : 'Could not reach the server at ${AppConfig.baseUrl}.\n'
              'Start it first: open a terminal, run "cd backend" then "python server.py".';
    }
    _busy = false;
    notifyListeners();
    return _user != null;
  }
}
