// ============================================================
// LANGUAGE PROVIDER — Premium Translation & Localization State
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _key = 'app_language';
  String _locale = 'id'; // Default to Indonesian

  String get locale => _locale;
  bool get isEnglish => _locale == 'en';

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'id';
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    _locale = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
    notifyListeners();
  }

  // Simple Translation Helper
  String translate(String key) {
    final dict = _localizedValues[_locale];
    if (dict == null) return key;
    return dict[key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'id': {
      'workspace': 'Workspace',
      'chat_ai': 'Chat AI',
      'writer_ai': 'AI Writer',
      'tools_ai': 'AI Tools',
      'settings': 'Pengaturan',
      'profile': 'Profil & Akun',
      'logout': 'Keluar dari Akun',
      'new_chat': 'Percakapan Baru',
      'topup': 'Beli Token',
      'balance': 'Saldo Token',
      'membership': 'Paket & Membership',
      'language': 'Bahasa',
      'theme_mode': 'Mode Tampilan',
      'theme_dark': 'Mode Gelap',
      'theme_light': 'Mode Terang',
      'cancel': 'Batal',
      'save': 'Simpan',
      'close': 'Tutup',
      'security': 'Keamanan & Password',
      'change_password': 'Ubah Password',
      'reset_password': 'Reset Password',
      'about': 'Tentang Aplikasi',
      'version': 'Versi',
    },
    'en': {
      'workspace': 'Workspace',
      'chat_ai': 'AI Chat',
      'writer_ai': 'AI Writer',
      'tools_ai': 'AI Tools',
      'settings': 'Settings',
      'profile': 'Profile & Account',
      'logout': 'Log Out',
      'new_chat': 'New Conversation',
      'topup': 'Buy Tokens',
      'balance': 'Token Balance',
      'membership': 'Plans & Membership',
      'language': 'Language',
      'theme_mode': 'Appearance Theme',
      'theme_dark': 'Dark Mode',
      'theme_light': 'Light Mode',
      'cancel': 'Cancel',
      'save': 'Save',
      'close': 'Close',
      'security': 'Security & Password',
      'change_password': 'Change Password',
      'reset_password': 'Reset Password',
      'about': 'About Application',
      'version': 'Version',
    }
  };
}
