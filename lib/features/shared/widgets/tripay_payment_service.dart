import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/services/api_service.dart';
import 'qris_payment_sheet.dart';

class TripayPaymentService {
  TripayPaymentService._();

  static Future<void> topUpQris({
    required BuildContext context,
    required int coins,
    VoidCallback? onSuccess,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final auth = context.read<AuthProvider>();
      final phone = auth.user?.phone ?? '';
      final body = {
        'coins': coins,
        'channel': 'QRIS2',
        'method': 'QRIS',
        'phone': phone.isEmpty ? '081234567890' : phone,
      };
      final response = await ApiService.instance.post(ApiConstants.topUp, body);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (response['status'] == 'success') {
        QrisPaymentSheet.show(
          context,
          qrUrl: response['paymentCode'] ?? response['payUrl'] ?? '',
          referenceId: response['referenceId'] ?? '',
          checkoutUrl: response['checkoutUrl'] ?? '',
        );
        onSuccess?.call();
      } else {
        _showError(context, response['message'] ?? 'Gagal membuat pembayaran.');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(context, 'Gagal membuat pembayaran: $e');
    }
  }

  static Future<void> upgradePlanQris({
    required BuildContext context,
    required int planId,
    required int amount,
    required String planName,
    VoidCallback? onSuccess,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final auth = context.read<AuthProvider>();
      final phone = auth.user?.phone ?? '';
      final body = {
        'planId': planId,
        'amount': amount,
        'channel': 'QRIS2',
        'method': 'QRIS',
        'item': 'Upgrade $planName',
        'phone': phone.isEmpty ? '081234567890' : phone,
      };
      final response =
          await ApiService.instance.post(ApiConstants.payments, body);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (response['status'] == 'success') {
        QrisPaymentSheet.show(
          context,
          qrUrl: response['paymentCode'] ?? response['payUrl'] ?? '',
          referenceId: response['referenceId'] ?? '',
          checkoutUrl: response['checkoutUrl'] ?? '',
        );
        onSuccess?.call();
      } else {
        _showError(context, response['message'] ?? 'Gagal membuat pembayaran.');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(context, 'Gagal membuat pembayaran: $e');
    }
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
