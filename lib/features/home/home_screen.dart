// ============================================================
// HOME SCREEN — Beranda Mobile Mirip Website PintarAja
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../shared/widgets/app_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Sempurnakan riset kamu dengan PintarAja',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Temukan layanan AI dan dukungan akademik yang pas untuk tugas, skripsi, dan presentasi kamu.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Mulai Sekarang',
                      onPressed: () => context.go('/chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Lihat Fitur',
                      isOutlined: true,
                      onPressed: () => context.go('/tools'),
                      textColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.softGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user?.name.split(' ').first ?? 'Mahasiswa'}!',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Dapatkan jawaban cepat, ringkas teks, dan buat tugas dengan bantuan AI PintarAja.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 44),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Layanan Unggulan',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildServiceCard(
                      label: 'AI Chat',
                      subtitle: 'Tanya apapun',
                      color: AppTheme.primary,
                      onTap: () => context.go('/chat'),
                    ),
                    _buildServiceCard(
                      label: 'Writer',
                      subtitle: 'Tulis otomatis',
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.go('/writer'),
                    ),
                    _buildServiceCard(
                      label: 'Paraphrase',
                      subtitle: 'Ubah kalimat',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => context.go('/tools'),
                    ),
                    _buildServiceCard(
                      label: 'Plagiarism',
                      subtitle: 'Cek orisinalitas',
                      color: const Color(0xFFF97316),
                      onTap: () => context.go('/plans'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Fitur Utama',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.3,
                children: [
                  _buildFeatureGridItem(
                    context: context,
                    title: 'AI Chat',
                    subtitle: 'Tanya apa saja',
                    icon: Icons.chat_bubble_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    route: '/chat',
                  ),
                  _buildFeatureGridItem(
                    context: context,
                    title: 'Writer',
                    subtitle: 'Tulis dengan AI',
                    icon: Icons.edit_rounded,
                    iconBg: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF7C3AED),
                    route: '/writer',
                  ),
                  _buildFeatureGridItem(
                    context: context,
                    title: 'Paraphrase',
                    subtitle: 'Ubah kalimat',
                    icon: Icons.swap_horiz_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0EA5E9),
                    route: '/tools',
                  ),
                  _buildFeatureGridItem(
                    context: context,
                    title: 'Plagiarism',
                    subtitle: 'Cek orisinalitas',
                    icon: Icons.verified_user_outlined,
                    iconBg: const Color(0xFFFDE68A),
                    iconColor: const Color(0xFFB45309),
                    route: '/plans',
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.auto_awesome, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGridItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}