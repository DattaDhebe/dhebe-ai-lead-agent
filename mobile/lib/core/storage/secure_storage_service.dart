import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _themeKey = 'theme_mode';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> saveUserJson(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> deleteUserJson() => _storage.delete(key: _userKey);

  Future<void> saveThemeMode(ThemeMode mode) {
    return _storage.write(key: _themeKey, value: mode.name);
  }

  Future<ThemeMode> readThemeMode() async {
    final raw = await _storage.read(key: _themeKey);

    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> clearSession() async {
    await deleteToken();
    await deleteUserJson();
  }
}
