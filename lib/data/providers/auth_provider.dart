// ============================================================
// AUTH PROVIDER — Login, Register, OTP, Logout
// ============================================================

import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  bool get isLoggedIn =>
      _status == AuthStatus.authenticated;

  int get tokenBalance =>
      _user?.quota ?? 0;

  AuthProvider() {
    _checkAuth();
  }

  // ==========================================================
  // CHECK AUTH
  // ==========================================================

  Future<void> _checkAuth() async {
    try {
      if (!StorageService.isLoggedIn) {
        _status =
            AuthStatus.unauthenticated;

        notifyListeners();
        return;
      }

      final userData =
          StorageService.getUser();

      if (userData != null) {
        _user =
            UserModel.fromJson(
          userData,
        );

        _status =
            AuthStatus.authenticated;

        notifyListeners();

        await refreshUser();
        return;
      }

      await _fetchUser();

      _status =
          AuthStatus.authenticated;

      notifyListeners();
    } catch (_) {
      _user = null;
      _status =
          AuthStatus.unauthenticated;

      await StorageService.clearAll();

      notifyListeners();
    }
  }

  // ==========================================================
  // FETCH USER
  // ==========================================================

  Future<void> _fetchUser() async {
    final data =
        await ApiService.instance.get(
      ApiConstants.user,
    );

    final rawUser =
        data is Map
            ? (data['data'] ?? data)
            : null;

    if (rawUser is! Map) {
      throw const ApiException(
        'Data user tidak valid.',
      );
    }

    _user =
        UserModel.fromJson(
      Map<String, dynamic>.from(
        rawUser,
      ),
    );

    await StorageService.saveUser(
      _user!.toJson(),
    );

    _status =
        AuthStatus.authenticated;
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<bool> login(
    String email,
    String password, {
    bool remember = true,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final data =
          await ApiService.instance.post(
        ApiConstants.login,
        {
          'email': email,
          'password': password,
          'remember': remember,
        },
        useAuth: false,
      );

      if (data is! Map) {
        throw const ApiException(
          'Response login tidak valid.',
        );
      }

      final token =
          data['token'] ??
          data['access_token'];

      if (token == null ||
          token.toString().isEmpty) {
        throw const ApiException(
          'Token tidak ditemukan.',
        );
      }

      await StorageService.saveToken(
        token.toString(),
      );

      final rawUser =
          data['user'];

      if (rawUser is Map) {
        _user =
            UserModel.fromJson(
          Map<String, dynamic>.from(
            rawUser,
          ),
        );

        await StorageService.saveUser(
          _user!.toJson(),
        );
      }

      _status =
          AuthStatus.authenticated;

      _setLoading(false);

      notifyListeners();

      // Refresh quota/profile di background.
      _refreshUserInBackground();

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error =
          'Terjadi kesalahan saat login.';

      _setLoading(false);
      return false;
    }
  }

  Future<void>
      _refreshUserInBackground() async {
    try {
      await _fetchUser();
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================
  // REGISTER + TURNSTILE
  // ==========================================================

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? referralCode,
    required String turnstileToken,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation':
            password,

        // WAJIB untuk backend PintarAja.
        'cf-turnstile-response':
            turnstileToken,

        if (referralCode != null &&
            referralCode.isNotEmpty)
          'referral_code':
              referralCode,
      };

      final data =
          await ApiService.instance.post(
        ApiConstants.register,
        body,
        useAuth: false,
      );

      // Register original PintarAja
      // mengirim status OTP, bukan token.
      if (data is Map) {
        final token =
            data['token'] ??
            data['access_token'];

        if (token != null) {
          await StorageService.saveToken(
            token.toString(),
          );

          await _fetchUser();
        }
      }

      _setLoading(false);

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error =
          'Terjadi kesalahan saat registrasi.';

      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // VERIFY OTP
  // ==========================================================

  Future<bool> verifyOtp(
    String email,
    String otp,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      final data =
          await ApiService.instance.post(
        '${ApiConstants.baseUrl}/verify-otp',
        {
          'email': email.trim(),
          'otp': otp.trim(),
        },
        useAuth: false,
      );

      if (data is! Map) {
        throw const ApiException(
          'Response OTP tidak valid.',
        );
      }

      final token =
          data['token'] ??
          data['access_token'];

      if (token == null ||
          token.toString().isEmpty) {
        throw const ApiException(
          'Token tidak ditemukan setelah verifikasi.',
        );
      }

      await StorageService.saveToken(
        token.toString(),
      );

      await _fetchUser();

      _status =
          AuthStatus.authenticated;

      _setLoading(false);

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error =
          'Terjadi kesalahan saat verifikasi OTP.';

      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // RESEND OTP
  // ==========================================================

  Future<bool> resendOtp(
    String email,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.instance.post(
        '${ApiConstants.baseUrl}/resend-otp',
        {
          'email': email.trim(),
        },
        useAuth: false,
      );

      _setLoading(false);

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error =
          'Gagal mengirim ulang OTP.';

      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    try {
      if (StorageService.getToken() != null) {
        await ApiService.instance.post(
          ApiConstants.logout,
          {},
        );
      }
    } catch (_) {}

    await StorageService.clearAll();

    _user = null;
    _status =
        AuthStatus.unauthenticated;
    _error = null;

    notifyListeners();
  }

  // ==========================================================
  // REFRESH USER
  // ==========================================================

  // ==========================================================
  // REFRESH USER
  // ==========================================================

  Future<void> refreshUser() async {
    try {
      await _fetchUser();
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================
  // UPDATE PROFILE (PUT /api/profiles)
  // ==========================================================

  Future<bool> updateProfile({
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.instance.put(
        ApiConstants.updateProfile,
        {
          'name': name.trim(),
          if (phone != null) 'phone': phone.trim(),
        },
      );

      await refreshUser();
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Gagal memperbarui profil.';
      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // CHANGE PASSWORD (PUT /api/profiles/password)
  // ==========================================================

  Future<bool> changePassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.instance.put(
        ApiConstants.changePassword,
        {
          if (oldPassword != null && oldPassword.isNotEmpty)
            'password_old': oldPassword,
          'password': newPassword,
        },
      );

      await refreshUser();
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Gagal mengubah password.';
      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // REDEEM COUPON (POST /api/profiles/redeem)
  // ==========================================================

  Future<bool> redeemCoupon(String code) async {
    _setLoading(true);
    _error = null;

    try {
      await ApiService.instance.post(
        ApiConstants.redeemCoupon,
        {
          'code': code.trim(),
        },
      );

      await refreshUser();
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Gagal menukarkan kupon.';
      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  void _setLoading(
    bool value,
  ) {
    _isLoading = value;
    notifyListeners();
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }
}