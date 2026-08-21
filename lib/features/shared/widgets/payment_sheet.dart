import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/storage_service.dart';
import 'qris_payment_sheet.dart';

class PaymentSelectionSheet extends StatefulWidget {
  final String itemName;
  final double price;
  final VoidCallback onPaymentSuccess;
  final String phone;
  final String type;
  final int? planId;
  final String? discountCode;
  final int? coins;

  const PaymentSelectionSheet({
    super.key,
    required this.itemName,
    required this.price,
    required this.onPaymentSuccess,
    required this.phone,
    this.type = 'subscription',
    this.planId,
    this.discountCode,
    this.coins,
  });

  static void show(
    BuildContext context, {
    required String itemTitle,
    required int amount,
    required VoidCallback onPaymentSuccess,
    String phone = '',
    String type = 'subscription',
    int? planId,
    String? discountCode,
    int? coins,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentSelectionSheet(
        itemName: itemTitle,
        price: amount.toDouble(),
        onPaymentSuccess: onPaymentSuccess,
        phone: phone,
        type: type,
        planId: planId,
        discountCode: discountCode,
        coins: coins,
      ),
    );
  }

  static Future<void> processDirectQris(
    BuildContext context, {
    required int amount,
    int? coins,
    String type = 'topup',
    String phone = '08123456789',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    bool dialogPopped = false;

    try {
      final token = StorageService.getToken();
      final body = <String, dynamic>{
        'method': 'QRIS2',
        'channel': 'QRIS2',
        'type': type,
        'phone': phone,
      };
      if (coins != null) {
        body['coins'] = coins;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.topUp),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      Navigator.pop(context); // Close loading dialog
      dialogPopped = true;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QrisPaymentSheet(
            qrUrl: data['qr_url'] ?? data['checkout_url'] ?? '',
            referenceId: data['reference'] ?? data['reference_id'] ?? '',
            checkoutUrl: data['checkout_url'] ?? data['pay_url'] ?? '',
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal memproses pembayaran. Code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!dialogPopped) {
        Navigator.pop(context); // Close loading dialog
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan atau data tidak valid.')),
      );
    }
  }

  @override
  State<PaymentSelectionSheet> createState() => _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends State<PaymentSelectionSheet> {
  bool _isLoading = false;
  String? _error;
  String _selectedMethod = 'QRIS2';

  late TextEditingController _phoneController;
  late TextEditingController _promoController;

  final Map<String, List<Map<String, String>>> _paymentGroups = {
    'QRIS': [
      {'id': 'QRIS2', 'name': 'QRIS', 'icon': 'qris'},
    ],
    'E-WALLET': [
      {'id': 'DANA', 'name': 'DANA', 'icon': 'dana'},
      {'id': 'OVO', 'name': 'OVO', 'icon': 'ovo'},
      {'id': 'SHOPEEPAY', 'name': 'ShopeePay', 'icon': 'shopeepay'},
    ],
    'VIRTUAL ACCOUNT': [
      {'id': 'BCAVA', 'name': 'BCA VA', 'icon': 'bca'},
      {'id': 'BNIVA', 'name': 'BNI VA', 'icon': 'bni'},
      {'id': 'BRIVA', 'name': 'BRI VA', 'icon': 'bri'},
      {'id': 'BSIVA', 'name': 'BSI VA', 'icon': 'bsi'},
      {'id': 'MANDIRIVA', 'name': 'Mandiri VA', 'icon': 'mandiri'},
    ],
    'MINI MARKET': [
      {'id': 'ALFAMART', 'name': 'Alfamart', 'icon': 'alfamart'},
      {'id': 'INDOMARET', 'name': 'Indomaret', 'icon': 'indomaret'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
    _promoController = TextEditingController(text: widget.discountCode ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

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

      final Map<String, dynamic> body = {
        'method': _selectedMethod,
        'channel': _selectedMethod,
        'type': widget.type,
        'phone': phone,
      };

      if (widget.type == 'subscription' && widget.planId != null) {
        body['planId'] = widget.planId;
        body['amount'] = widget.price.toInt();
      } else if (widget.type == 'topup' && widget.coins != null) {
        body['coins'] = widget.coins;
      }

      final promo = _promoController.text.trim();
      if (promo.isNotEmpty) {
        body['discount_code'] = promo;
      }

      final endpoint = widget.type == 'subscription'
          ? ApiConstants.payments
          : ApiConstants.topUp;

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        Navigator.pop(context); // Close checkout

        // data keys differ: topup returns qr_url, subscription returns paymentCode
        final qrUrl = data['qr_url'] ??
            data['paymentCode'] ??
            data['checkout_url'] ??
            '';
        final referenceId = data['reference'] ??
            data['reference_id'] ??
            data['referenceId'] ??
            '';
        final checkoutUrl = data['checkout_url'] ??
            data['checkoutUrl'] ??
            data['pay_url'] ??
            data['payUrl'] ??
            '';

        if (_selectedMethod.startsWith('QRIS')) {
          if (!mounted) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => QrisPaymentSheet(
              qrUrl: qrUrl,
              referenceId: referenceId,
              checkoutUrl: checkoutUrl,
            ),
          );
          widget.onPaymentSuccess();
        } else {
          if (checkoutUrl.isNotEmpty) {
            final uri = Uri.parse(checkoutUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
          widget.onPaymentSuccess();
        }
      } else {
        setState(() {
          _error = 'Gagal memproses pembayaran. Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan jaringan.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMethodGroup(String title, List<Map<String, String>> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.map((m) {
            final isSelected = _selectedMethod == m['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedMethod = m['id']!),
              child: Container(
                width: (MediaQuery.of(context).size.width - 40 - 20) /
                    2, // 2 columns
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.05)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m['name']!,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final email = user?.email ?? 'user@example.com';
    final name = user?.name ?? 'User';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Checkout',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    Text('Select payment method',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  final methodsColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _paymentGroups.entries
                        .map((e) => _buildMethodGroup(e.key, e.value))
                        .toList(),
                  );

                  final infoColumn = Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Info
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('Payment Info',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('E-mail',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: email,
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Name',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: name,
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No phone *',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '08xxxxxxxxxx',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppTheme.borderLight)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 32),

                        // Solution
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Solution for professionals',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary)),
                                  Text(widget.itemName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Promo & Total
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary)),
                              Text('Rp. ${widget.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  decoration: InputDecoration(
                                    hintText: 'ENTER PROMO CODE',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppTheme.borderLight)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                ),
                                child: const Text('Use',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // Error
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.error, fontSize: 13)),
                          ),

                        // Pay Button
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.bolt_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 4),
                                        Text('Pay Now',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: methodsColumn),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: infoColumn),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          methodsColumn,
                          const SizedBox(height: 24),
                          infoColumn,
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
