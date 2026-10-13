import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Saved login (token + user) so the app can skip the login page next time.
class SavedSession {
  final String token;
  final AppUser user;
  const SavedSession(this.token, this.user);
}

abstract class SessionStore {
  Future<void> save(String token, AppUser user);
  Future<SavedSession?> load();
  Future<void> clear();
}

/// Persists the session on the device (browser local storage on web).
class PrefsSessionStore implements SessionStore {
  static const _tokenKey = 'session_token';
  static const _userKey = 'session_user';

  @override
  Future<void> save(String token, AppUser user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
    await p.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<SavedSession?> load() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_tokenKey);
    final raw = p.getString(_userKey);
    if (token == null || raw == null) return null;
    try {
      return SavedSession(
          token, AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
    await p.remove(_userKey);
  }
}

/// For tests.
class MemorySessionStore implements SessionStore {
  SavedSession? _saved;

  @override
  Future<void> save(String token, AppUser user) async =>
      _saved = SavedSession(token, user);

  @override
  Future<SavedSession?> load() async => _saved;

  @override
  Future<void> clear() async => _saved = null;
}
