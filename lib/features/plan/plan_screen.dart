// ============================================================
// PLAN SCREEN — Premium Subscriptions & Pricing Plans
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/plan_provider.dart';
import '../../data/providers/auth_provider.dart';

import '../shared/widgets/payment_sheet.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = AppTheme.getBg(context);


    return Scaffold(
      backgroundColor: themeBg,
      appBar: AppBar(
        backgroundColor: themeBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.getTextColor(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Paket & Langganan',
          style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                    const SizedBox(height: 12),
                    Text(provider.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadPlans(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.plans.isEmpty) {
            return Center(
              child: Text(
                'Belum ada paket tersedia saat ini.',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: provider.plans.length,
            itemBuilder: (_, i) {
              final plan = provider.plans[i];
              return _PlanCard(plan: plan);
            },
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final cardColor = AppTheme.getSurface(context);
    final borderColor = plan.isPopular ? AppTheme.primary : AppTheme.getBorder(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    if (plan.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Populer',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.isFree ? 'Gratis' : 'Rp ${plan.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    if (!plan.isFree)
                      Text(
                        ' / bulan',
                        style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mendapatkan ${plan.credits} Kredit AI',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...plan.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                color: AppTheme.getTextSecondary(context),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openPaymentSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isPopular ? AppTheme.primary : AppTheme.getBorder(context),
                      foregroundColor: plan.isPopular ? Colors.white : AppTheme.getTextColor(context),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      plan.isFree ? 'Gunakan Gratis' : 'Langganan Sekarang',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return PaymentSelectionSheet(
          itemName: 'Langganan ${plan.name}',
          price: plan.price,
          onPaymentSuccess: () async {
            Navigator.pop(bottomSheetCtx);
            await context.read<AuthProvider>().refreshUser();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembayaran berhasil! Paket langganan kamu telah aktif.')),
              );
            }
          },
        );
      },
    );
  }
}
