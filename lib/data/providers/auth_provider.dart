// ============================================================
// AUTH PROVIDER — PintarAja
// Login, Register, OTP, Session, Logout
// ============================================================

import 'dart:async';

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

  // ==========================================================
  // GETTERS
  // ==========================================================

  AuthStatus get status => _status;

  UserModel? get user => _user;

  String? get error => _error;

  bool get isLoading => _isLoading;

  bool get isLoggedIn => _status == AuthStatus.authenticated;

  int get tokenBalance => _user?.quota ?? 0;

  Map<String, int> _tokenCosts = {};

  bool _tokenCostsLoaded = false;

  Map<String, int> get tokenCosts => _tokenCosts;

  int get topupMinCoins {
    final value = _tokenCosts['cost_topup_amount'] ?? 0;
    return value > 0 ? value : 10;
  }

  double get topupPricePerCoin {
    final amount = topupMinCoins;
    if (amount <= 0) return 0;
    final price = _tokenCosts['cost_topup_price'] ?? 0;
    return price / amount;
  }

  Future<void> loadTokenCosts({bool force = false}) async {
    if (_tokenCostsLoaded && !force) return;

    try {
      final data = await ApiService.instance.get(
        ApiConstants.tokenCosts,
      );

      if (data is Map && data['data'] is Map) {
        _tokenCosts = (data['data'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            int.tryParse(value.toString()) ?? 0,
          ),
        );

        _tokenCostsLoaded = true;

        notifyListeners();
      }
    } catch (_) {
      // Biaya token tetap memakai nilai default.
    }
  }

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  AuthProvider() {
    _checkAuth();
  }

  // ==========================================================
  // CHECK AUTH
  // ==========================================================

  Future<void> _checkAuth() async {
    try {
      final token = StorageService.getToken();

      // ------------------------------------------------------
      // TIDAK ADA TOKEN
      // ------------------------------------------------------

      if (token == null || token.isEmpty) {
        _user = null;

        _status = AuthStatus.unauthenticated;

        notifyListeners();

        return;
      }

      // ------------------------------------------------------
      // COBA AMBIL USER DARI STORAGE
      // ------------------------------------------------------

      final userData = StorageService.getUser();

      if (userData != null) {
        try {
          _user = UserModel.fromJson(
            Map<String, dynamic>.from(
              userData,
            ),
          );

          _status = AuthStatus.authenticated;

          notifyListeners();

          // Refresh data user dari server.
          await refreshUser();

          return;
        } catch (_) {
          // Data user lokal rusak /
          // tidak sesuai model.
          await StorageService.deleteUser();

          _user = null;
        }
      }

      // ------------------------------------------------------
      // USER BELUM ADA DI STORAGE
      // ------------------------------------------------------

      await _fetchUser();

      _status = AuthStatus.authenticated;

      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearAuthState();
      } else {
        _user = null;

        _status = AuthStatus.unauthenticated;

        await StorageService.clearAuth();

        notifyListeners();
      }
    } catch (_) {
      _user = null;

      _status = AuthStatus.unauthenticated;

      await StorageService.clearAuth();

      notifyListeners();
    }
  }

  // ==========================================================
  // FETCH USER
  // ==========================================================

  Future<void> _fetchUser() async {
    final data = await ApiService.instance.get(
      ApiConstants.user,
    );

    // Backend bisa mengembalikan:
    //
    // {
    //   "data": {...}
    // }
    //
    // atau langsung:
    //
    // {...}

    final rawUser = data is Map ? (data['data'] ?? data) : null;

    if (rawUser is! Map) {
      throw const ApiException(
        'Data user tidak valid.',
      );
    }

    _user = UserModel.fromJson(
      Map<String, dynamic>.from(
        rawUser,
      ),
    );

    // --------------------------------------------------------
    // SIMPAN USER SESUAI REMEMBER ME
    // --------------------------------------------------------

    final shouldPersist = StorageService.rememberMe;

    await StorageService.saveUser(
      _user!.toJson(),
      persistent: shouldPersist,
    );

    _status = AuthStatus.authenticated;
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<bool> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    _setLoading(true);

    _error = null;

    try {
      final data = await ApiService.instance.post(
        ApiConstants.login,
        {
          'email': email.trim(),
          'password': password,
          'remember': remember,
        },
        useAuth: false,
      );

      // ------------------------------------------------------
      // VALIDASI RESPONSE
      // ------------------------------------------------------

      if (data is! Map) {
        throw const ApiException(
          'Response login tidak valid.',
        );
      }

      // ------------------------------------------------------
      // TOKEN
      // ------------------------------------------------------

      final token = data['token'] ?? data['access_token'];

      if (token == null || token.toString().isEmpty) {
        throw const ApiException(
          'Token tidak ditemukan.',
        );
      }

      // ------------------------------------------------------
      // SIMPAN TOKEN
      //
      // remember = true
      // → token disimpan persistent
      //
      // remember = false
      // → token hanya session
      // ------------------------------------------------------

      await StorageService.saveToken(
        token.toString(),
        remember: remember,
      );

      // ------------------------------------------------------
      // USER
      // ------------------------------------------------------

      final rawUser = data['user'];

      if (rawUser is Map) {
        _user = UserModel.fromJson(
          Map<String, dynamic>.from(
            rawUser,
          ),
        );

        await StorageService.saveUser(
          _user!.toJson(),
          persistent: remember,
        );
      }

      // ------------------------------------------------------
      // AUTHENTICATED
      // ------------------------------------------------------

      _status = AuthStatus.authenticated;

      _setLoading(false);

      notifyListeners();

      // Refresh data terbaru dari server
      // tanpa menghambat proses login.
      _refreshUserInBackground();

      return true;
    } on ApiException catch (e) {
      _error = e.message;

      _setLoading(false);

      return false;
    } catch (_) {
      _error = 'Terjadi kesalahan saat login.';

      _setLoading(false);

      return false;
    }
  }

  // ==========================================================
  // GOOGLE LOGIN
  // ==========================================================

  Future<bool> loginWithGoogle(
      {String? googleToken, String? accessToken}) async {
    _setLoading(true);
    _error = null;

    try {
      final body = <String, String>{};
      if (googleToken != null) body['id_token'] = googleToken;
      if (accessToken != null) body['access_token'] = accessToken;
      // fallback: send token as both for compatibility
      if (googleToken != null && accessToken == null) {
        body['access_token'] = googleToken;
      }

      final data = await ApiService.instance.post(
        ApiConstants.loginGoogle,
        body,
        useAuth: false,
      );

      if (data is! Map) {
        throw const ApiException('Response login Google tidak valid.');
      }

      final token =
          data['token'] ?? data['access_token'] ?? data['data']?['token'];
      if (token == null || token.toString().isEmpty) {
        throw const ApiException('Token otentikasi Google tidak ditemukan.');
      }

      await StorageService.saveToken(token.toString(), remember: true);

      final rawUser = data['user'] ?? data['data']?['user'];
      if (rawUser is Map) {
        _user = UserModel.fromJson(Map<String, dynamic>.from(rawUser));
        await StorageService.saveUser(_user!.toJson(), persistent: true);
      } else {
        await _fetchUser();
      }

      _status = AuthStatus.authenticated;
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Gagal melakukan login dengan Google.';
      _setLoading(false);
      return false;
    }
  }

  // ==========================================================
  // BACKGROUND USER REFRESH
  // ==========================================================

  Future<void> _refreshUserInBackground() async {
    try {
      await _fetchUser();

      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearAuthState();
      }
    } catch (_) {
      // Jangan mengganggu user
      // jika refresh gagal.
    }
  }

  // ==========================================================
  // REGISTER
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
      final body = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
        'cf-turnstile-response': turnstileToken,
      };

      if (referralCode != null && referralCode.trim().isNotEmpty) {
        body['referral_code'] = referralCode.trim();
      }

      final data = await ApiService.instance.post(
        ApiConstants.register,
        body,
        useAuth: false,
      );

      // ------------------------------------------------------
      // JIKA REGISTER LANGSUNG MEMBERIKAN TOKEN
      // ------------------------------------------------------

      if (data is Map) {
        final token = data['token'] ?? data['access_token'];

        if (token != null && token.toString().isNotEmpty) {
          await StorageService.saveToken(
            token.toString(),
            remember: false,
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
      _error = 'Terjadi kesalahan saat registrasi.';

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
      final data = await ApiService.instance.post(
        ApiConstants.verifyOtp,
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

      final token = data['token'] ?? data['access_token'];

      if (token == null || token.toString().isEmpty) {
        throw const ApiException(
          'Token tidak ditemukan setelah verifikasi.',
        );
      }

      // Setelah OTP berhasil,
      // token disimpan sebagai session.
      await StorageService.saveToken(
        token.toString(),
        remember: false,
      );

      await _fetchUser();

      _status = AuthStatus.authenticated;

      _setLoading(false);

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _error = e.message;

      _setLoading(false);

      return false;
    } catch (_) {
      _error = 'Terjadi kesalahan saat verifikasi OTP.';

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
        ApiConstants.resendOtp,
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
      _error = 'Gagal mengirim ulang OTP.';

      _setLoading(false);

      return false;
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    try {
      final token = StorageService.getToken();

      if (token != null && token.isNotEmpty) {
        await ApiService.instance.post(
          ApiConstants.logout,
          {},
        );
      }
    } catch (_) {
      // Logout lokal tetap dilakukan
      // meskipun request server gagal.
    }

    await _clearAuthState();
  }

  // ==========================================================
  // CLEAR AUTH
  // ==========================================================

  Future<void> _clearAuthState() async {
    await StorageService.clearAuth();

    _user = null;

    _status = AuthStatus.unauthenticated;

    _error = null;

    notifyListeners();
  }

  // ==========================================================
  // HANDLE UNAUTHORIZED (GLOBAL 401 HOOK)
  // ==========================================================

  /// Dipanggil dari [ApiService.onUnauthorized] ketika request apapun
  /// menerima HTTP 401. Membersihkan state dan memberitahu router agar
  /// mengarahkan user kembali ke halaman login.
  Future<void> handleUnauthorized() async {
    if (_status != AuthStatus.authenticated) return;

    await _clearAuthState();
  }

  // ==========================================================
  // REFRESH USER
  // ==========================================================

  Future<void> refreshUser() async {
    try {
      unawaited(loadTokenCosts());

      await _fetchUser();

      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearAuthState();
      }
    } catch (_) {
      // Jangan logout user hanya karena
      // refresh gagal karena jaringan.
    }
  }

  // ==========================================================
  // UPDATE PROFILE
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
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
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
  // CHANGE PASSWORD
  // ==========================================================

  Future<bool> changePassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);

    _error = null;

    try {
      final body = <String, dynamic>{
        'password': newPassword,
      };

      if (oldPassword != null && oldPassword.trim().isNotEmpty) {
        body['password_old'] = oldPassword;
      }

      await ApiService.instance.put(
        ApiConstants.changePassword,
        body,
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
  // REDEEM COUPON
  // ==========================================================

  Future<bool> redeemCoupon(
    String code,
  ) async {
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
