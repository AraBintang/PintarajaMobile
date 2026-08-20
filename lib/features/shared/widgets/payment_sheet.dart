// ============================================================
// PAYMENT SHEET — Premium Payment Sheet with Tripay API
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/storage_service.dart';

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

  @override
  State<PaymentSelectionSheet> createState() => _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends State<PaymentSelectionSheet> {
  String? _selectedMethod;
  bool _isProcessing = false;
  bool _paymentCreated = false;

  // Payment result data
  String? _paymentCode;
  String? _checkoutUrl;
  List<dynamic>? _instructions;
  String? _discountMessage;
  String? _errorMessage;

  // Phone controller
  late final TextEditingController _phoneController;
  Timer? _expiryTimer;
  int _remainingSeconds = 0;

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'qris',
      'channel': 'qris2',
      'method': 'QRIS',
      'name': 'QRIS (Gopay / OVO / Dana / LinkAja)',
      'icon': Icons.qr_code_2_rounded,
    },
    {
      'id': 'bca',
      'channel': 'bcava',
      'method': 'BCA VA',
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'mandiri',
      'channel': 'mandiriva',
      'method': 'Mandiri VA',
      'name': 'Mandiri Virtual Account',
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'bni',
      'channel': 'bniva',
      'method': 'BNI VA',
      'name': 'BNI Virtual Account',
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'bri',
      'channel': 'briva',
      'method': 'BRI VA',
      'name': 'BRI Virtual Account',
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'indomaret',
      'channel': 'indomaret',
      'method': 'Indomaret',
      'name': 'Indomaret',
      'icon': Icons.store_rounded,
    },
    {
      'id': 'alfamart',
      'channel': 'alfamart',
      'method': 'Alfamart',
      'name': 'Alfamart',
      'icon': Icons.store_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _expiryTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedMethodInfo {
    if (_selectedMethod == null) return null;
    return _methods.firstWhere(
      (m) => m['id'] == _selectedMethod,
      orElse: () => _methods.first,
    );
  }

  String get _authToken => StorageService.getToken() ?? '';

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryColor = AppTheme.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.getBorder(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _paymentCreated
                      ? 'Detail Pembayaran'
                      : 'Pilih Metode Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.itemName,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total Tagihan: Rp ${widget.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if (_discountMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _discountMessage!,
                style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ---- Error message ----
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ---- Processing state ----
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Menghubungkan ke gateway pembayaran...',
                      ),
                    ],
                  ),
                ),
              )

            // ---- Payment result view ----
            else if (_paymentCreated)
              _buildPaymentResult(context)

            // ---- Method selection view ----
            else ...[
              // Phone number input
              Text(
                'Nomor Telepon',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  hintStyle: TextStyle(
                    color: secondaryColor.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppTheme.getBg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.getBorder(context),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.getBorder(context),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment method list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  children: _methods.map((method) {
                    final isSelected = _selectedMethod == method['id'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.getBorder(context),
                        ),
                        color: isSelected
                            ? AppTheme.primary.withValues(
                                alpha: 0.05,
                              )
                            : Colors.transparent,
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(
                            () => _selectedMethod = method['id'] as String,
                          );
                        },
                        leading: Icon(
                          method['icon'] as IconData,
                          color: isSelected ? AppTheme.primary : secondaryColor,
                        ),
                        title: Text(
                          method['name'] as String,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                size: 20,
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod == null ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      48,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================================
  // PAYMENT RESULT WIDGET
  // ========================================================

  Widget _buildPaymentResult(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryColor = AppTheme.getTextSecondary(context);
    final info = _selectedMethodInfo;
    final isQRIS = info != null && info['id'] == 'qris';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expiry countdown
        if (_remainingSeconds > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: AppTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Batas waktu: ${_formatDuration(_remainingSeconds)}',
                  style: const TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // QR Code display for QRIS
        if (isQRIS && _paymentCode != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.getBorder(context),
                ),
              ),
              child: Column(
                children: [
                  Image.network(
                    _paymentCode!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[100],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan QR di atas',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan dengan aplikasi e-wallet atau mobile banking',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ]

        // VA / payment code display
        else if (!isQRIS && _paymentCode != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kode Pembayaran',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _paymentCode!,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        _copyToClipboard(_paymentCode!);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Instructions
        if (_instructions != null && _instructions!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Cara Pembayaran',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...(_instructions!).map((inst) {
            final step = inst as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step['step'] != null)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(
                        right: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${step['step']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      '${step['title'] ?? ''}\n${step['desc'] ?? ''}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: 16),

        // Checkout URL button
        if (_checkoutUrl != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchCheckoutUrl(),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Buka Halaman Pembayaran'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(
                  color: AppTheme.primary,
                ),
                minimumSize: const Size(
                  double.infinity,
                  48,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        if (_checkoutUrl != null) const SizedBox(height: 8),

        // Copy payment code button
        if (_paymentCode != null && !isQRIS) const SizedBox(height: 0),

        // Success / done button
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                double.infinity,
                48,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Saya sudah membayar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // PROCESS PAYMENT — CALL REAL API
  // ========================================================

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan nomor telepon terlebih dahulu.';
      });
      return;
    }

    final info = _selectedMethodInfo;
    if (info == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final token = _authToken;
      if (token.isEmpty) {
        throw Exception('Anda belum login. Silakan login terlebih dahulu.');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final body = <String, dynamic>{
        'channel': info['channel'],
        'method': info['method'],
        'phone': phone,
      };

      String url;

      if (widget.type == 'topup') {
        url = ApiConstants.topUp;
        body['coins'] = widget.coins ?? widget.price.toInt();
      } else {
        url = ApiConstants.payments;
        body['planId'] = widget.planId ?? 0;
        body['amount'] = widget.price.toInt();
        body['item'] = widget.itemName;
        if (widget.discountCode != null && widget.discountCode!.isNotEmpty) {
          body['discountCode'] = widget.discountCode;
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final responseData = jsonDecode(
        response.body,
      ) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final payCode = responseData['paymentCode'] as String?;
        final chkUrl = responseData['checkoutUrl'] as String?;
        final expired = responseData['expiredAt'] as int?;
        final instr = responseData['instructions'] as List<dynamic>?;
        final discount = responseData['discountInfo'] as Map<String, dynamic>?;

        setState(() {
          _isProcessing = false;
          _paymentCreated = true;
          _paymentCode = payCode;
          _checkoutUrl = chkUrl;
          _instructions = instr;
          if (discount != null && discount['message'] != null) {
            _discountMessage = discount['message'] as String;
          }
        });

        if (expired != null) {
          _startExpiryCountdown(expired);
        }
      } else {
        final msg = responseData['message'] as String? ??
            'Gagal membuat pembayaran. Silakan coba lagi.';
        setState(() {
          _isProcessing = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  // ========================================================
  // HELPERS
  // ========================================================

  void _startExpiryCountdown(int expiredAtEpoch) {
    _expiryTimer?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _remainingSeconds = expiredAtEpoch - now;

    if (_remainingSeconds <= 0) return;

    _expiryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            timer.cancel();
          }
        });
      },
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode disalin: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchCheckoutUrl() async {
    if (_checkoutUrl == null) return;
    final uri = Uri.parse(_checkoutUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
