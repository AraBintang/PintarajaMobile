import os

token_dialog_code = """
  void _showTokenDialog() {
    final authProvider = context.read<AuthProvider>();
    final tokenBalance = authProvider.tokenBalance;
    final minCoins = authProvider.topupMinCoins;
    final pricePerCoin = authProvider.topupPricePerCoin;
    final priceLabel = pricePerCoin % 1 == 0
        ? pricePerCoin.toInt().toString()
        : pricePerCoin.toStringAsFixed(2);

    int selectedCoins = minCoins > 50 ? minCoins : 50;
    final TextEditingController coinsController =
        TextEditingController(text: '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            final totalPrice = selectedCoins * pricePerCoin;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundApp,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: AppTheme.getBorder(context),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Token & Top Up',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.getTextColor(context))),
                          IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sisa Token Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sisa Token Anda',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.diamond_rounded,
                                    color: Color(0xFFFCD34D), size: 24),
                                const SizedBox(width: 8),
                                Text('',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                Text('token',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Up Section
                      Text('Top Up Token',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.getTextColor(context))),
                      const SizedBox(height: 4),
                      Text('Harga: Rp  / token',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 10),

                      // Preset Amount Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...[10, 50, 100, 500, 1000]
                              .where((amount) => amount >= minCoins)
                              .map((amount) {
                            final isSelected = selectedCoins == amount;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedCoins = amount;
                                  coinsController.text = '';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.borderLight),
                                ),
                                child: Text('',
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Custom Amount
                      TextField(
                        controller: coinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Token (Min. )',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.diamond_rounded),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            setModalState(() => selectedCoins = parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Total Price
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                            Text('Rp ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Top Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: selectedCoins < minCoins
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final auth = context.read<AuthProvider>();
                                  final phone =
                                      auth.user?.phone?.isNotEmpty == true
                                          ? auth.user!.phone!
                                          : '08123456789';

                                  await PaymentSelectionSheet.processDirectQris(
                                    this.context,
                                    amount: totalPrice.round(),
                                    coins: selectedCoins,
                                    phone: phone,
                                  );

                                  await auth.refreshUser();
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  'Bayar via QRIS - Rp ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
"""

token_chip_code = """
class _TokenChip extends StatelessWidget {
  final int balance;
  final VoidCallback onTap;

  const _TokenChip({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_rounded,
                color: Color(0xFFF59E0B), size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"""

def add_to_file(path, is_transcribe=False):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Add imports if missing
    imports = ""
    if "import 'package:provider/provider.dart';" not in content:
        imports += "import 'package:provider/provider.dart';\n"
    if "import '../../data/providers/auth_provider.dart';" not in content:
        imports += "import '../../data/providers/auth_provider.dart';\n"
    if "import '../shared/widgets/payment_sheet.dart';" not in content:
        imports += "import '../shared/widgets/payment_sheet.dart';\n"
        
    if imports:
        content = content.replace("import '../../core/constants/api_constants.dart';", imports + "import '../../core/constants/api_constants.dart';")

    # 2. Add _showTokenDialog right before the first Widget build(BuildContext context)
    if 'void _showTokenDialog()' not in content:
        idx = content.find('  @override\n  Widget build(BuildContext context) {')
        if idx != -1:
            content = content[:idx] + token_dialog_code + '\n' + content[idx:]
            
    # 3. Add actions to AppBar
    appbar_start = content.find("title: Text(")
    if appbar_start != -1 and "actions: [" not in content[appbar_start:appbar_start+500]:
        # Find the end of title: Text( ... ),
        end_idx = content.find("),", content.find("style: TextStyle(", appbar_start)) + 2
        
        actions_code = """
        actions: [
          _TokenChip(
            balance: context.watch<AuthProvider>().tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 10),
        ],"""
        
        # actually find the closing of title: Text(...)
        title_end = content.find("),", content.find("fontWeight: FontWeight.w700,", appbar_start)) + 3
        # just to be safe, search for leading comma or just insert before ody:?
        # Actually it's easier to insert after 	itle: Text( ... ),
        idx_to_insert = content.find("),", content.find("fontWeight:", appbar_start)) + 2
        content = content[:idx_to_insert] + actions_code + content[idx_to_insert:]

    # 4. Add _TokenChip class at the end
    if 'class _TokenChip extends' not in content:
        content += '\n' + token_chip_code

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

add_to_file(r'lib\features\plagiarism\plagiarism_screen.dart')
add_to_file(r'lib\features\transcribe\transcribe_screen.dart', True)
print("Done safely")
