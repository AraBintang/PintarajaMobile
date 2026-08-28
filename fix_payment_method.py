import glob

file = 'lib/features/shared/widgets/payment_method_page.dart'
with open(file, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _selectedMethod and _paymentGroups
content = content.replace(
    "String _selectedMethod = 'QRIS';",
    "String _selectedMethod = 'Xendit';"
)

content = content.replace(
    """  static const Map<String, List<Map<String, String>>> _paymentGroups = {
    'QRIS': [
      {'id': 'QRIS', 'name': 'QRIS'},
    ],
    'KARTU KREDIT': [
      {'id': 'VISA', 'name': 'Visa / Mastercard'},
    ],
  };""",
    """  static const Map<String, List<Map<String, String>>> _paymentGroups = {
    'METODE PEMBAYARAN': [
      {'id': 'Xendit', 'name': 'Pembayaran Xendit (QRIS, VA, dsb)'},
    ],
  };"""
)

content = content.replace(
    """      if (_selectedMethod.startsWith('QRIS') && qrUrl.isNotEmpty) {
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
      }""",
    """      if (checkoutUrl.isNotEmpty) {
        final uri = Uri.parse(checkoutUrl);
        await launchExternal(uri);
      } else if (qrUrl.isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QrisPaymentSheet(
            qrUrl: qrUrl,
            referenceId: referenceId,
            checkoutUrl: '',
          ),
        );
      }"""
)

with open(file, 'w', encoding='utf-8') as f:
    f.write(content)
