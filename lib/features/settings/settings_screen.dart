// ============================================================
// SETTINGS SCREEN — Production Ready
// Beautiful UI with gradient header, smooth cards, animations
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../shared/widgets/payment_sheet.dart';
import '../shared/widgets/qris_payment_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundApp,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // App Bar Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/chat');
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                          const Expanded(
                            child: Text(
                              'Pengaturan',
                              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // User Profile Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                user?.initials ?? 'PA',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Pengguna PintarAja',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? 'email@pintaraja.com',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?.plan ?? 'Free',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. AKUN
                  _buildSectionHeader('Akun Saya', Icons.person_outline_rounded),
                  _SettingsTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Profil & Informasi Akun',
                    subtitle: user?.name ?? '-',
                    onTap: () => _showProfileDialog(context, auth),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Ubah Password',
                    subtitle: 'Atur ulang kata sandi akun',
                    onTap: () => _showPasswordDialog(context, auth),
                  ),

                  const SizedBox(height: 20),

                  // 2. PLAN
                  _buildSectionHeader('Plan & Membership', Icons.workspace_premium_rounded),
                  _SettingsTile(
                    icon: Icons.card_membership_rounded,
                    title: 'Upgrade Plan',
                    subtitle: 'Weekly Rp17rb • Monthly Rp49rb • Annual Rp29rb/bln',
                    badge: user?.plan ?? 'Free',
                    onTap: () => _showPlanModal(context),
                  ),
                  _SettingsTile(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Redeem Kupon / Voucher',
                    subtitle: 'Tukarkan kode promo atau voucher',
                    onTap: () => _showRedeemDialog(context, auth),
                  ),

                  const SizedBox(height: 20),

                  // 3. PENYIMPANAN
                  _buildSectionHeader('Penyimpanan & File', Icons.folder_open_rounded),
                  _SettingsTile(
                    icon: Icons.cloud_queue_rounded,
                    title: 'File Manager AI Writer',
                    subtitle: 'Kelola dokumen yang tersimpan',
                    onTap: () => _showFileManagerModal(context),
                  ),

                  const SizedBox(height: 20),

                  // 4. REFERRAL
                  _buildSectionHeader('Program Referral', Icons.group_add_rounded),
                  _SettingsTile(
                    icon: Icons.share_rounded,
                    title: 'Undang Teman & Dapatkan Bonus',
                    subtitle: 'Bagikan kode referral ke teman',
                    onTap: () => _showReferralModal(context),
                  ),

                  const SizedBox(height: 20),

                  // 5. RIWAYAT
                  _buildSectionHeader('Riwayat', Icons.history_rounded),
                  _SettingsTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Riwayat Order & Pembayaran',
                    subtitle: 'Top-up, Plagiarisme, & Upgrade',
                    onTap: () => _showHistoryModal(context),
                  ),

                  const SizedBox(height: 20),

                  // 6. KELUAR
                  _buildSectionHeader('Sesi', Icons.logout_rounded),
                  _DangerTile(
                    icon: Icons.logout_rounded,
                    title: 'Keluar dari Akun',
                    onTap: () => _confirmLogout(context, auth),
                  ),

                  const SizedBox(height: 30),

                  // App Version
                  Center(
                    child: Text(
                      'PintarAja v1.0.0',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PROFILE DIALOG
  // ==========================================================

  void _showProfileDialog(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'No. Telepon / WhatsApp',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Text('Email: ${user?.email ?? "-"}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.updateProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Profil berhasil diperbarui!' : 'Gagal memperbarui profil.')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PASSWORD DIALOG
  // ==========================================================

  void _showPasswordDialog(BuildContext context, AuthProvider auth) {
    final oldPw = TextEditingController();
    final newPw = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Saat Ini',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.changePassword(
                oldPassword: oldPw.text,
                newPassword: newPw.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Password berhasil diubah!' : 'Gagal mengubah password.')),
                );
              }
            },
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PLAN MODAL
  // ==========================================================

  void _showPlanModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(ApiConstants.plans),
            headers: {
              'Accept': 'application/json',
            },
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  const Center(child: Text('Gagal memuat plan')),
                  const SizedBox(height: 16),
                ],
              );
            }

            final response = snapshot.data!;
            if (response.statusCode != 200) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  const Center(child: Text('Gagal memuat plan')),
                  const SizedBox(height: 16),
                ],
              );
            }

            final List<dynamic> plans = jsonDecode(response.body);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                const Text('Upgrade Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Akses AI tanpa batas & kuota token lebih besar', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 18),
                ...plans.map((plan) {
                  final name = plan['name'] ?? '';
                  final price = plan['price'] ?? 0;
                  final description = plan['description'] ?? '';
                  final badge = plan['badge'] as String?;
                  final formattedPrice = 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlanOptionTile(
                      title: name,
                      price: formattedPrice,
                      desc: description,
                      badge: badge,
                      onTap: () => _triggerPayment(ctx, name, price),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _triggerPayment(BuildContext ctx, String planName, int amount) {
      Navigator.pop(ctx);
      _createPlanPayment(context, planName, amount);
  }
  
  Future<void> _createPlanPayment(BuildContext currentContext, String planName, int amount) async {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
        final response = await ApiService.instance.post(ApiConstants.topUp, {
          'coins': (amount / 1000).ceil(),
          'channel': 'QRIS2',
          'method': 'QRIS',
          'phone': '081234567890',
        });
        
        if (!mounted) return;
        Navigator.pop(currentContext);
        
        if (response['status'] == 'success' || response['paymentCode'] != null || response['checkoutUrl'] != null) {
          QrisPaymentSheet.show(
            currentContext,
            qrUrl: response['paymentCode'] ?? response['payUrl'] ?? '',
            referenceId: response['referenceId'] ?? '',
            checkoutUrl: response['checkoutUrl'] ?? '',
          );
        } else {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal membuat pembayaran QRIS.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(currentContext);
        ScaffoldMessenger.of(currentContext).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
  }

  // ==========================================================
  // REDEEM
  // ==========================================================

  void _showRedeemDialog(BuildContext context, AuthProvider auth) {
    final codeController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Redeem Kupon', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Masukkan kode kupon',
            prefixIcon: const Icon(Icons.videogame_asset_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.redeemCoupon(codeController.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Kupon berhasil ditukarkan!' : 'Kode kupon tidak valid.')),
                );
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILE MANAGER
  // ==========================================================

  void _showFileManagerModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.sizeOf(context).height * 0.5,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10)))),
            const Text('File Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Penyimpanan AI Writer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  SizedBox(height: 8),
                  LinearProgressIndicator(value: 0.09, minHeight: 8, backgroundColor: AppTheme.surfaceMuted, color: AppTheme.primary),
                  SizedBox(height: 6),
                  Text('45.2 MB / 500 MB digunakan', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open_rounded, color: AppTheme.textMuted, size: 48),
                    SizedBox(height: 8),
                    Text('Belum ada file', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // REFERRAL
  // ==========================================================

  void _showReferralModal(BuildContext context) {
    final token = StorageService.getToken();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(ApiConstants.referrals),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ],
              );
            }

            if (snapshot.hasError || snapshot.data?.statusCode != 200) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  const Center(child: Text('Gagal memuat data referral')),
                  const SizedBox(height: 16),
                ],
              );
            }

            final data = jsonDecode(snapshot.data!.body);
            final String refCode = data['referral_code'] ?? '';
            final String refLink = data['referral_link'] ?? '';
            final int totalReferrals = data['total_referrals'] ?? 0;
            final int pendingDiscount = data['pending_discount'] ?? 0;
            final bool hasFreeMonth = data['has_free_month'] ?? false;
            final progress = data['progress'] ?? {};
            final int currentInCycle = progress['current_in_cycle'] ?? 0;
            final int toNextFree = progress['to_next_free'] ?? 7;
            final List<dynamic> usages = data['usages'] ?? [];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10))),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.card_giftcard_rounded, size: 36, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 14),
                  const Text('Program Referral', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReferrals teman sudah bergabung • Diskon pending: $pendingDiscount%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress ke Free 1 Bulan: $currentInCycle/7',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            if (hasFreeMonth)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(6)),
                                child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: currentInCycle / 7,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceMuted,
                          color: hasFreeMonth ? AppTheme.success : AppTheme.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$toNextFree lagi untuk FREE 1 bulan',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#1-6: Setiap teman yang mendaftar & melakukan pembelian berapapun +10% diskon untukmu (max 60%)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('#7: Orang ke-7 = kamu dapat FREE 1 bulan plan berbayar!', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('#8+: Siklus berulang — orang ke-8 mulai siklus diskon baru lagi', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Referral code
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(refCode, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: refCode));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode referral disalin!')));
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Salin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link: $refLink')));
                          },
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Referral list
                  if (usages.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Teman yang sudah bergabung (${usages.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...usages.map((u) {
                      final userName = u['user_name'] ?? '';
                      final joinedAt = u['joined_at'] ?? '';
                      final rewardLabel = u['reward_label'] ?? '';
                      final isUsed = u['is_used'] ?? false;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary)),
                                  Text(joinedAt, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUsed ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(rewardLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isUsed ? AppTheme.success : AppTheme.warning)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // HISTORY
  // ==========================================================

  void _showHistoryModal(BuildContext context) {
    int currentPage = 1;
    String selectedStatus = '';

    void fetchData(StateSetter setModalState, {int page = 1, String? status}) async {
      final token = StorageService.getToken();
      final queryParams = {
        'page': page.toString(),
        'per_page': '10',
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      final uri = Uri.parse(ApiConstants.payments).replace(queryParameters: queryParams);
      try {
        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
        if (response.statusCode == 200) {
          setModalState(() {});
        }
      } catch (_) {}
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filters = [
            {'label': 'Semua', 'value': ''},
            {'label': 'Menunggu', 'value': '0'},
            {'label': 'Berhasil', 'value': '1'},
            {'label': 'Refund', 'value': '2'},
            {'label': 'Kadaluarsa', 'value': '3'},
          ];
          final token = StorageService.getToken();

          return Container(
            height: MediaQuery.sizeOf(context).height * 0.7,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10)))),
                const Text('Riwayat Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final selected = selectedStatus == f['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(f['label']!, style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                          selected: selected,
                          selectedColor: AppTheme.primary,
                          onSelected: (val) {
                            if (val) {
                              selectedStatus = f['value']!;
                              currentPage = 1;
                              fetchData(setModalState, page: currentPage, status: selectedStatus);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<http.Response>(
                    future: () {
                      final queryParams = {
                        'page': currentPage.toString(),
                        'per_page': '10',
                      };
                      if (selectedStatus.isNotEmpty) {
                        queryParams['status'] = selectedStatus;
                      }
                      final uri = Uri.parse(ApiConstants.payments).replace(queryParameters: queryParams);
                      return http.get(uri, headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                      });
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data?.statusCode != 200) {
                        return const Center(child: Text('Gagal memuat riwayat'));
                      }

                      final Map<String, dynamic> body = jsonDecode(snapshot.data!.body);
                      final List<dynamic> items = body['data'] ?? [];

                      if (items.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted, size: 48),
                              SizedBox(height: 8),
                              Text('Belum ada riwayat', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            ],
                          ),
                        );
                      }

                      Color statusColor(int code) {
                        switch (code) {
                          case 0: return AppTheme.warning;
                          case 1: return AppTheme.success;
                          case 2: return AppTheme.primary;
                          case 3: return AppTheme.error;
                          default: return AppTheme.textMuted;
                        }
                      }

                      IconData typeIcon(String type) {
                        switch (type) {
                          case 'subscription': return Icons.credit_card_rounded;
                          case 'topup': return Icons.diamond_rounded;
                          case 'plagiarism': return Icons.plagiarism_rounded;
                          default: return Icons.receipt_rounded;
                        }
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final int statusCode = item['statusCode'] ?? 0;
                          final int amount = item['amount'] ?? 0;
                          final String planName = item['planName'] ?? '';
                          final String statusStr = item['status'] ?? '';
                          final String createdAt = item['createdAt'] ?? '';
                          final String txType = item['transactionType'] ?? '';
                          final DateTime? date = DateTime.tryParse(createdAt);
                          final String formattedDate = date != null ? '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}' : createdAt;
                          final String formattedAmount = 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

                          return _buildHistoryTile(
                            planName,
                            formattedAmount,
                            formattedDate,
                            statusStr,
                            statusColor(statusCode),
                            icon: typeIcon(txType),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _monthName(int month) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month];
  }

  Widget _buildHistoryTile(String title, String price, String date, String status, Color statusColor, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(
              icon ?? (status == 'Berhasil' ? Icons.check_circle_rounded : Icons.schedule_rounded),
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$date • $price', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await auth.logout();
                    if (context.mounted) context.go('/auth/login');
                  },
                  child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS TILE
// ============================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(badge!, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
      ),
    );
  }
}

// ============================================================
// DANGER TILE
// ============================================================

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.error, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.error)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
      ),
    );
  }
}

// ============================================================
// PLAN OPTION TILE
// ============================================================

class _PlanOptionTile extends StatelessWidget {
  final String title;
  final String price;
  final String desc;
  final String? badge;
  final VoidCallback onTap;

  const _PlanOptionTile({
    required this.title,
    required this.price,
    required this.desc,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge != null ? AppTheme.primary : AppTheme.borderLight, width: badge != null ? 1.5 : 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(price, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
      ),
    );
  }
}
