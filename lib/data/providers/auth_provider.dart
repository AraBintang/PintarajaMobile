// ============================================================
// AUTH PROVIDER — Login, Register, Logout
// ============================================================

import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuth();
  }

  // ── Cek apakah sudah login ─────────────────────────────────
  Future<void> _checkAuth() async {
    if (StorageService.isLoggedIn) {
      final userData = StorageService.getUser();
      if (userData != null) {
        _user = UserModel.fromJson(userData);
        _status = AuthStatus.authenticated;
      } else {
        try {
          await _fetchUser();
        } catch (_) {
          _status = AuthStatus.unauthenticated;
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Fetch user dari API ─────────────────────────────────────
  Future<void> _fetchUser() async {
    final data = await ApiService.instance.get(ApiConstants.user);
    _user = UserModel.fromJson(data['data'] ?? data);
    await StorageService.saveUser(_user!.toJson());
    _status = AuthStatus.authenticated;
  }

  // ── LOGIN ─────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final data = await ApiService.instance.post(
        ApiConstants.login,
        {'email': email, 'password': password},
        useAuth: false,
      );

      final token = data['token'] ?? data['access_token'];
      if (token == null) throw ApiException('Token tidak ditemukan.');

      await StorageService.saveToken(token.toString());
      await _fetchUser();
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  // ── REGISTER ──────────────────────────────────────────────
  Future<bool> register(String name, String email, String password,
      {String? referralCode}) async {
    _setLoading(true);
    _error = null;

    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      };

      final data = await ApiService.instance.post(
        ApiConstants.register,
        body,
        useAuth: false,
      );

      final token = data['token'] ?? data['access_token'];
      if (token != null) {
        await StorageService.saveToken(token.toString());
        await _fetchUser();
      }

      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await ApiService.instance.post(ApiConstants.logout, {});
    } catch (_) {}

    await StorageService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Refresh user data ─────────────────────────────────────
  Future<void> refreshUser() async {
    try {
      await _fetchUser();
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
