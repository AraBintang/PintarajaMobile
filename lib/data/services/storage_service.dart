// ============================================================
// PINTARAJA — STORAGE SERVICE
// Persistent auth + temporary session
// ============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

class StorageService {
  static late SharedPreferences _prefs;

  // Session hanya hidup selama aplikasi berjalan.
  static String? _sessionToken;
  static Map<String, dynamic>? _sessionUser;

  // ==========================================================
  // INIT
  // ==========================================================

  static Future<void> init() async {
    _prefs =
        await SharedPreferences.getInstance();

    // Jangan membawa session lama.
    //
    // _sessionToken dan _sessionUser memang
    // hanya memory sementara sehingga ketika
    // aplikasi benar-benar dimulai ulang,
    // keduanya otomatis null.
    _sessionToken = null;
    _sessionUser = null;
  }

  // ==========================================================
  // PERSISTENT TOKEN
  // ==========================================================

  static String? get persistentToken {
    return _prefs.getString(
      AppConstants.tokenKey,
    );
  }

  static Future<void> savePersistentToken(
    String token,
  ) async {
    await _prefs.setString(
      AppConstants.tokenKey,
      token,
    );
  }

  static Future<void>
      deletePersistentToken() async {
    await _prefs.remove(
      AppConstants.tokenKey,
    );
  }

  // ==========================================================
  // TEMPORARY SESSION TOKEN
  // ==========================================================

  static String? get sessionToken {
    return _sessionToken;
  }

  static Future<void> saveSessionToken(
    String token,
  ) async {
    _sessionToken = token;
  }

  static Future<void>
      deleteSessionToken() async {
    _sessionToken = null;
  }

  // ==========================================================
  // ACTIVE TOKEN
  // ==========================================================

  static String? getToken() {
    // Session token diprioritaskan.
    return _sessionToken ??
        persistentToken;
  }

  static bool get isLoggedIn {
    final token = getToken();

    return token != null &&
        token.isNotEmpty;
  }

  // ==========================================================
  // SAVE TOKEN
  // ==========================================================

  static Future<void> saveToken(
    String token, {
    bool remember = false,
  }) async {
    final cleanToken =
        token.trim();

    if (cleanToken.isEmpty) {
      return;
    }

    if (remember) {
      // ------------------------------------------------------
      // REMEMBER ME ON
      // ------------------------------------------------------

      _sessionToken = null;

      await savePersistentToken(
        cleanToken,
      );
    } else {
      // ------------------------------------------------------
      // REMEMBER ME OFF
      // ------------------------------------------------------

      // Sangat penting:
      // hapus token persistent lama.
      //
      // Kalau sebelumnya user pernah login
      // dengan Remember Me ON, token lama
      // tidak boleh membuat user otomatis
      // login lagi.
      await deletePersistentToken();

      await saveSessionToken(
        cleanToken,
      );
    }
  }

  // ==========================================================
  // DELETE TOKEN
  // ==========================================================

  static Future<void> deleteToken() async {
    _sessionToken = null;

    await deletePersistentToken();
  }

  // ==========================================================
  // USER DATA
  // ==========================================================

  static Map<String, dynamic>? getUser() {
    // --------------------------------------------------------
    // SESSION USER
    // --------------------------------------------------------

    if (_sessionUser != null) {
      return Map<String, dynamic>.from(
        _sessionUser!,
      );
    }

    // --------------------------------------------------------
    // PERSISTENT USER
    // --------------------------------------------------------

    final data =
        _prefs.getString(
      AppConstants.userKey,
    );

    if (data == null ||
        data.isEmpty) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(data);

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(
        decoded,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // SAVE USER
  // ==========================================================

  static Future<void> saveUser(
    Map<String, dynamic> user, {
    bool persistent = false,
  }) async {
    if (persistent) {
      // ------------------------------------------------------
      // PERSISTENT USER
      // ------------------------------------------------------

      _sessionUser = null;

      await _prefs.setString(
        AppConstants.userKey,
        jsonEncode(user),
      );
    } else {
      // ------------------------------------------------------
      // SESSION USER
      // ------------------------------------------------------

      // Hapus data persistent lama.
      await _prefs.remove(
        AppConstants.userKey,
      );

      _sessionUser =
          Map<String, dynamic>.from(
        user,
      );
    }
  }

  // ==========================================================
  // DELETE USER
  // ==========================================================

  static Future<void> deleteUser() async {
    _sessionUser = null;

    await _prefs.remove(
      AppConstants.userKey,
    );
  }

  // ==========================================================
  // REMEMBER ME STATUS
  // ==========================================================

  static bool get rememberMe {
    final token =
        persistentToken;

    return token != null &&
        token.isNotEmpty;
  }

  // ==========================================================
  // CLEAR AUTH ONLY
  // ==========================================================

  static Future<void> clearAuth() async {
    _sessionToken = null;
    _sessionUser = null;

    await _prefs.remove(
      AppConstants.tokenKey,
    );

    await _prefs.remove(
      AppConstants.userKey,
    );
  }

  // ==========================================================
  // CLEAR EVERYTHING
  // ==========================================================

  static Future<void> clearAll() async {
    _sessionToken = null;
    _sessionUser = null;

    await _prefs.clear();
  }
}