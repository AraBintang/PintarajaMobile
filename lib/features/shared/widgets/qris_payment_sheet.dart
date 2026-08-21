import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class QrisPaymentSheet extends StatelessWidget {
  final String qrUrl;
  final String referenceId;
  final String checkoutUrl;

  const QrisPaymentSheet({
    super.key,
    required this.qrUrl,
    required this.referenceId,
    required this.checkoutUrl,
  });

  static void show(
    BuildContext context, {
    required String qrUrl,
    required String referenceId,
    required String checkoutUrl,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrisPaymentSheet(
        qrUrl: qrUrl,
        referenceId: referenceId,
        checkoutUrl: checkoutUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.getBorder(context), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pembayaran QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.getTextColor(context))),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Scan QR Code di bawah menggunakan aplikasi M-Banking atau e-Wallet Anda (Gopay, OVO, DANA, dll).', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Image.network(qrUrl, width: 220, height: 220, fit: BoxFit.contain, 
              errorBuilder: (_,__,___) => const SizedBox(width: 220, height: 220, child: Center(child: Icon(Icons.qr_code, size: 80, color: Colors.grey)))),
          ),
          const SizedBox(height: 24),
          const Text('Atau buka halaman checkout Tripay:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uri = Uri.parse(checkoutUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Buka Halaman Checkout'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
