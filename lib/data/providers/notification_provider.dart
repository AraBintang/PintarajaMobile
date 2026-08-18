// ============================================================
// NOTIFICATION PROVIDER — Persistent Notification Settings
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _keyEnabled = 'notif_enabled';
  static const String _keyChat = 'notif_chat';
  static const String _keyPromo = 'notif_promo';

  bool _enabled = true;
  bool _chatNotif = true;
  bool _promoNotif = false;

  bool get enabled => _enabled;
  bool get chatNotif => _chatNotif;
  bool get promoNotif => _promoNotif;

  NotificationProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? true;
    _chatNotif = prefs.getBool(_keyChat) ?? true;
    _promoNotif = prefs.getBool(_keyPromo) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    notifyListeners();
  }

  Future<void> setChatNotif(bool value) async {
    _chatNotif = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyChat, value);
    notifyListeners();
  }

  Future<void> setPromoNotif(bool value) async {
    _promoNotif = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromo, value);
    notifyListeners();
  }
}
