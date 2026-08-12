// ============================================================
// STORAGE SERVICE — SharedPreferences wrapper
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Token ─────────────────────────────────────────────────
  static String? getToken() => _prefs.getString(AppConstants.tokenKey);

  static Future<void> saveToken(String token) async {
    await _prefs.setString(AppConstants.tokenKey, token);
  }

  static Future<void> deleteToken() async {
    await _prefs.remove(AppConstants.tokenKey);
  }

  static bool get isLoggedIn => getToken() != null;

  // ── User Data ─────────────────────────────────────────────
  static Map<String, dynamic>? getUser() {
    final data = _prefs.getString(AppConstants.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(AppConstants.userKey, jsonEncode(user));
  }

  static Future<void> deleteUser() async {
    await _prefs.remove(AppConstants.userKey);
  }

  // ── Clear All ─────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
