import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionManager {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _loginTimeKey = 'login_time';
  static const int _sessionDurationHours = 24; // Session duration in hours

  static Future<void> saveSession({
    required int userId,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if session exists
    if (!prefs.containsKey(_userIdKey) || !prefs.containsKey(_loginTimeKey)) {
      return null;
    }

    // Check if session has expired
    final loginTimeStr = prefs.getString(_loginTimeKey);
    if (loginTimeStr == null) return null;

    final loginTime = DateTime.parse(loginTimeStr);
    final now = DateTime.now();
    final difference = now.difference(loginTime);

    if (difference.inHours >= _sessionDurationHours) {
      // Session expired, clear all data
      await clearSession();
      return null;
    }

    return {
      'user_id': prefs.getInt(_userIdKey),
      'username': prefs.getString(_usernameKey),
      'email': prefs.getString(_emailKey),
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_loginTimeKey);
  }

  static Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null;
  }
} 