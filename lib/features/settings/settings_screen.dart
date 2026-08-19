// ============================================================
// SETTINGS SCREEN â€” Restructured for PintarAja Mobile
// 6 Main Sections: Profile, Plan, File, Referral, History, Sign Out
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../shared/widgets/payment_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _historyFilter = 'All'; // All, Waiting, Paid, Expired

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chat');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Akun Ringkas
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        user?.initials ?? 'PA',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna PintarAja',
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'email@pintaraja.com',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user?.plan ?? 'Free Plan',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. PROFILE
              _buildSectionHeader('Profile', Icons.person_outline_rounded),
              _SettingsTile(
                icon: Icons.account_circle_outlined,
                title: 'Profil & Informasi Akun',
                subtitle: 'Nama: ${user?.name ?? '-'}\nPhone: ${user?.phone?.isNotEmpty == true ? user!.phone : '-'}\nEmail: ${user?.email ?? '-'}',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showProfileDialog(context, auth),
              ),
              _SettingsTile(
                icon: Icons.lock_reset_rounded,
                title: 'Reset Password',
                subtitle: 'Ubah atau atur ulang kata sandi kamu',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showPasswordDialog(context, auth),
              ),

              const SizedBox(height: 16),

              // 2. PLAN
              _buildSectionHeader('Plan & Upgrade', Icons.workspace_premium_rounded),
              _SettingsTile(
                icon: Icons.card_membership_rounded,
                title: 'Upgrade Plan & Membership',
                subtitle: 'Weekly (Rp 17rb) â€¢ Monthly (Rp 49rb) â€¢ Annual (Rp 29rb/bln)',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showPlanModal(context),
              ),
              _SettingsTile(
                icon: Icons.card_giftcard_rounded,
                title: 'Redeem Code / Voucher',
                subtitle: 'Tukarkan kode kupon promo atau voucher',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showRedeemDialog(context, auth),
              ),

              const SizedBox(height: 16),

              // 3. FILE (500MB STORAGE MANAGER)
              _buildSectionHeader('File & Storage Manager', Icons.folder_open_rounded),
              _SettingsTile(
                icon: Icons.cloud_queue_rounded,
                title: 'Pengelolaan File AI Writer',
                subtitle: 'Penyimpanan: 45.2 MB / 500 MB digunakan',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showFileManagerModal(context),
              ),

              const SizedBox(height: 16),

              // 4. REFERRAL
              _buildSectionHeader('Program Referral', Icons.group_add_rounded),
              _SettingsTile(
                icon: Icons.share_rounded,
                title: 'Undang Teman & Dapatkan Bonus',
                subtitle: 'Kode Referral: PINTAR-${user?.id ?? "1001"}',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showReferralModal(context, user?.id ?? 1001),
              ),

              const SizedBox(height: 16),

              // 5. HISTORY
              _buildSectionHeader('History & Order History', Icons.history_rounded),
              _SettingsTile(
                icon: Icons.receipt_long_rounded,
                title: 'Riwayat Order & Pengecekan',
                subtitle: 'Riwayat Top-up & Riwayat Plagiarisme',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                onTap: () => _showHistoryModal(context),
              ),

              const SizedBox(height: 16),

              // 6. SIGN OUT
              _buildSectionHeader('Sesi & Akses', Icons.logout_rounded),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out (Keluar)',
                subtitle: 'Keluar dari akun PintarAja',
                iconColor: Colors.redAccent,
                titleColor: Colors.redAccent,
                onTap: () => _confirmLogout(context, auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'No Telepon / WhatsApp'),
            ),
            const SizedBox(height: 10),
            Text('Email: ${user?.email ?? "-"}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
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

  void _showPasswordDialog(BuildContext context, AuthProvider auth) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset / Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Saat Ini'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.changePassword(
                oldPassword: oldPasswordController.text,
                newPassword: newPasswordController.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Password berhasil diubah!' : 'Gagal mengubah password.')),
                );
              }
            },
            child: const Text('Ubah Password'),
          ),
        ],
      ),
    );
  }

  void _showPlanModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilihan Upgrade Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Akses AI tanpa batas & kuota token lebih besar', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 18),
            _PlanOptionTile(
              title: 'Weekly Plan',
              price: 'Rp 17.000 / minggu',
              desc: 'Cocok untuk kebutuhan tugas cepat 7 hari',
              badge: null,
              onTap: () => _triggerPayment(ctx, 'Weekly Plan', 17000),
            ),
            const SizedBox(height: 10),
            _PlanOptionTile(
              title: 'Monthly Plan',
              price: 'Rp 49.000 / bulan',
              desc: 'Pilihan paling populer untuk mahasiswa & penulis',
              badge: 'POPULER',
              onTap: () => _triggerPayment(ctx, 'Monthly Plan', 49000),
            ),
            const SizedBox(height: 10),
            _PlanOptionTile(
              title: 'Annual / Tahunan Plan',
              price: 'Rp 29.000 / bulan (Hemat 40%)',
              desc: 'Ditagih Rp 348.000 / tahun untuk fleksibilitas 12 bulan',
              badge: 'TERHEMAT',
              onTap: () => _triggerPayment(ctx, 'Annual Plan', 348000),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerPayment(BuildContext ctx, String planName, int amount) {
    Navigator.pop(ctx);
    PaymentSelectionSheet.show(
      context,
      itemTitle: 'Upgrade $planName',
      amount: amount,
      onPaymentSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran $planName berhasil! Plan akun kamu telah di-upgrade.')),
        );
      },
    );
  }

  void _showRedeemDialog(BuildContext context, AuthProvider auth) {
    final codeController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Kupon / Voucher'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Masukkan Kode Kupon (misal: PINTARPRO)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
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

  void _showFileManagerModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Penyimpanan File AI Writer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Kapasitas Penyimpanan Maksimal: 500 MB', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.09, minHeight: 8, backgroundColor: AppTheme.surfaceMuted, color: AppTheme.primary),
            const SizedBox(height: 8),
            const Text('Digunakan: 45.2 MB dari 500 MB (9%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.description_rounded, color: AppTheme.primary),
              title: const Text('Draft_Skripsi_Bab1.docx'),
              subtitle: const Text('12.4 MB â€¢ AI Writer Document'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
              title: const Text('Jurnal_Referensi_APA7.pdf'),
              subtitle: const Text('32.8 MB â€¢ PDF Reference'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showReferralModal(BuildContext context, int userId) {
    final refCode = 'PINTAR-$userId';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text('Kode Referral Kamu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Bagikan kode ini ke temanmu dan dapatkan bonus +100 Token!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Text(refCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 2)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: refCode));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode referral berhasil disalin!')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Kode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka menu bagikan kode...')));
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Bagikan Kode'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filters = ['All', 'Waiting', 'Paid', 'Expired'];
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Riwayat Order & Plagiarisme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: filters.map((f) {
                    final selected = _historyFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(f, style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppTheme.textPrimary)),
                        selected: selected,
                        selectedColor: AppTheme.primary,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _historyFilter = f);
                            setState(() => _historyFilter = f);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      _buildHistoryTile('Top-up 500 Token', 'Rp 25.000', '18 Aug 2026', 'PAID', Colors.green),
                      _buildHistoryTile('Turnitin Check - Bab 1 Skripsi.docx', 'Rp 22.000', '17 Aug 2026', 'PAID', Colors.green),
                      _buildHistoryTile('Upgrade Monthly Pro Plan', 'Rp 49.000', '10 Aug 2026', 'PAID', Colors.green),
                      _buildHistoryTile('Turnitin Check - Draft Jurnal.pdf', 'Rp 22.000', '05 Aug 2026', 'EXPIRED', Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTile(String title, String price, String date, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('$date â€¢ $price', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun PintarAja?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) context.go('/auth/login');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

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
    required this.badge,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.titleColor,
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
        dense: true,
        leading: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
        title: Text(
          title,
          style: TextStyle(color: titleColor ?? AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
        ),
        trailing: trailing,
      ),
    );
  }
}
