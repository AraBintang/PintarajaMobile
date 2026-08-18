// ============================================================
// PAYMENT SHEET — Premium Reusable Payment Sheet
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaymentSelectionSheet extends StatefulWidget {
  final String itemName;
  final double price;
  final VoidCallback onPaymentSuccess;

  const PaymentSelectionSheet({
    super.key,
    required this.itemName,
    required this.price,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentSelectionSheet> createState() => _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends State<PaymentSelectionSheet> {
  String? _selectedMethod;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'qris', 'name': 'QRIS (Gopay / OVO / Dana / LinkAja)', 'icon': Icons.qr_code_2_rounded},
    {'id': 'bca', 'name': 'BCA Virtual Account', 'icon': Icons.account_balance_rounded},
    {'id': 'mandiri', 'name': 'Mandiri Virtual Account', 'icon': Icons.account_balance_rounded},
    {'id': 'bni', 'name': 'BNI Virtual Account', 'icon': Icons.account_balance_rounded},
    {'id': 'bri', 'name': 'BRI Virtual Account', 'icon': Icons.account_balance_rounded},
    {'id': 'indomaret', 'name': 'Indomaret / Alfamart', 'icon': Icons.store_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryColor = AppTheme.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                'Pilih Metode Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.itemName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Total Tagihan: Rp ${widget.price.toStringAsFixed(0)}',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 12),
                    Text('Menghubungkan ke gateway pembayaran...'),
                  ],
                ),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: _methods.map((method) {
                  final isSelected = _selectedMethod == method['id'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.getBorder(context)),
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.transparent,
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() => _selectedMethod = method['id'] as String);
                      },
                      leading: Icon(method['icon'] as IconData, color: isSelected ? AppTheme.primary : secondaryColor),
                      title: Text(method['name'] as String,
                          style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                          : const Icon(Icons.circle_outlined, size: 20),
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
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _processPayment() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
            SizedBox(width: 10),
            Text('Pembayaran Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Terima kasih! Pembayaran simulasi berhasil diproses.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onPaymentSuccess();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
