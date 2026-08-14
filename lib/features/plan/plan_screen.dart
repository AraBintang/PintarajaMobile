// ============================================================
// PLAN SCREEN — Subscriptions & Pricing Plans
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/plan_provider.dart';
import '../shared/widgets/app_button.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        title: const Text('Paket & Langganan', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!, style: const TextStyle(color: AppTheme.error)));
          }

          if (provider.plans.isEmpty) {
            return const Center(child: Text('Belum ada paket tersedia', style: TextStyle(color: AppTheme.textSecondary)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular ? AppTheme.primary : AppTheme.divider,
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.isFree ? 'Gratis' : 'Rp ${plan.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    if (!plan.isFree)
                      const Text(' / bulan', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Mendapatkan ${plan.credits} kredit AI', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                ...plan.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                AppButton(label: plan.isFree ? 'Gunakan Gratis' : 'Langganan Sekarang', gradient: plan.isPopular ? AppTheme.primaryGradient : null, onPressed: plan.isFree ? null : () {}),
              ],
            ),
          ),
          if (plan.isPopular)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Text('Terpopuler', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
