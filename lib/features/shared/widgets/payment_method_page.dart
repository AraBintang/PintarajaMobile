// ============================================================
// PAYMENT METHOD PAGE — PintarAja
// Full-screen checkout untuk Upgrade Plan:
// pilih metode → POST /payments (dengan item "-Period")
// → QRIS: tampilkan QR, lainnya: buka checkout URL.
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/storage_service.dart';
import 'payment_sheet.dart';
import 'qris_payment_sheet.dart';

class PaymentMethodPage extends StatefulWidget {
  final int planId;
  final String planName;
  final int amount;
  final String phone;
  final String period; // Weekly | Monthly | Yearly
  final VoidCallback onPaymentSuccess;

  const PaymentMethodPage({
    super.key,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.phone,
    required this.period,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  bool _isLoading = false;
  String? _error;
  String _selectedMethod = 'QRIS2';

  late final TextEditingController _phoneController;
  late final TextEditingController _promoController;

  static const Map<String, List<Map<String, String>>> _paymentGroups = {
    'QRIS': [
      {'id': 'QRIS2', 'name': 'QRIS'},
    ],
    'KARTU KREDIT': [
      {'id': 'VISA', 'name': 'Visa / Mastercard'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
    _promoController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  String get _itemName => '${widget.planName} - ${widget.period}';

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Nomor HP tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = StorageService.getToken();

      final body = <String, dynamic>{
        'method': _selectedMethod,
        'channel': _selectedMethod,
        'type': 'subscription',
        'planId': widget.planId,
        'amount': widget.amount,
        // Suffix -Weekly/-Monthly/-Yearly dipakai backend untuk durasi.
        'item': _itemName,
        'phone': phone,
      };

      final promo = _promoController.text.trim();
      if (promo.isNotEmpty) {
        body['discount_code'] = promo;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.payments),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PaymentProcessException(
            PaymentSelectionSheet.parseErrorResponse(
                response.body, response.statusCode));
      }

      final data = (jsonDecode(response.body) as Map).cast<String, dynamic>();
      final parsed = PaymentSelectionSheet.parsePaymentResponse(data);

      final qrUrl = parsed['qrUrl'] ?? '';
      final referenceId = parsed['referenceId'] ?? '';
      final checkoutUrl = (parsed['checkoutUrl']?.isNotEmpty == true
              ? parsed['checkoutUrl']
              : parsed['payUrl']) ??
          '';

      if (!mounted) return;

      if (_selectedMethod.startsWith('QRIS') && qrUrl.isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QrisPaymentSheet(
            qrUrl: qrUrl,
            referenceId: referenceId,
            checkoutUrl: checkoutUrl,
          ),
        );
      } else if (checkoutUrl.isNotEmpty) {
        final uri = Uri.parse(checkoutUrl);
        await launchExternal(uri);
      }

      widget.onPaymentSuccess();

      if (!mounted) return;
      Navigator.of(context).pop();
    } on PaymentProcessException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan jaringan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> launchExternal(Uri uri) async {
    // url_launcher dipanggil via payment_sheet agar dependensi konsisten.
    await PaymentSelectionSheet.launchExternalUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        title: const Text('Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanSummary(),
                    const SizedBox(height: 20),
                    ..._paymentGroups.entries
                        .map((e) => _buildMethodGroup(e.key, e.value)),
                    const SizedBox(height: 20),
                    _buildDetailCard(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.10),
            AppTheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.planName} (${widget.period})',
                    style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text('Total: Rp ${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodGroup(String title, List<Map<String, String>> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.map((m) {
            final id = m['id']!;
            final isSelected = _selectedMethod == id;
            return GestureDetector(
              onTap: () => setState(() => _selectedMethod = id),
              child: Container(
                width: (MediaQuery.of(context).size.width - 32 - 10) / 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.06)
                      : AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                      width: isSelected ? 1.5 : 1),
                ),
                alignment: Alignment.center,
                child: Text(m['name']!,
                    style: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.getTextColor(context),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Pembayaran',
              style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Text('No. WhatsApp *',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '08xxxxxxxxxx',
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item',
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context), fontSize: 13)),
              Flexible(
                child: Text(_itemName,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pembayaran',
                  style: TextStyle(
                      color: AppTheme.getTextSecondary(context), fontSize: 13)),
              Text('Rp ${widget.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.error.withValues(alpha: 0.25))),
              child: Text(_error!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        border: const Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.surfaceMuted,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Bayar Sekarang',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
