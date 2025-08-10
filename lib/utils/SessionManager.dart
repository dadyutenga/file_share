import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys for storing data
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'username';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save session data
  static Future<void> saveSession({
    required String token,
    required String username,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _isLoggedInKey, value: 'true');
  }

  // Get auth token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get username
  static Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final isLoggedIn = await _storage.read(key: _isLoggedInKey);
    final token = await _storage.read(key: _tokenKey);
    return isLoggedIn == 'true' && token != null && token.isNotEmpty;
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  // Update token
  static Future<void> updateToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
}
