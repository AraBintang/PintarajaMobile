// ============================================================
// PROFILE SCREEN â€” Full Functional: Edit Profil, Reset Password,
//                  Redeem Kupon, Membership, Tema, Bahasa, Logout
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profil Akun',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppTheme.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // â”€â”€ Avatar + Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.bgSurface,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.initials ?? 'PA',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Pengguna PintarAja',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'email@example.com',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // Plan Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: AppTheme.accent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          user?.activePlanName ?? 'Free Plan',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // â”€â”€ Menu Akun â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildSectionLabel('Akun'),
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Informasi Akun',
              trailingText:
                  user?.phone?.isNotEmpty == true ? user!.phone : 'Edit',
              onTap: () => _showEditProfileDialog(context, auth),
            ),
            _buildMenuItem(
              icon: Icons.card_giftcard_rounded,
              title: 'Redeem Kupon & Voucher',
              onTap: () => _showRedeemCouponDialog(context, auth),
            ),
            _buildMenuItem(
              icon: Icons.security_rounded,
              title: 'Keamanan & Password',
              trailingText: 'Ubah / Reset',
              onTap: () => _showSecurityDialog(context, auth),
            ),
            _buildMenuItem(
              icon: Icons.workspace_premium_outlined,
              title: 'Paket & Langganan',
              trailingText: user?.activePlanName ?? 'Free',
              onTap: () => _showMembershipDialog(context, auth),
            ),

            const SizedBox(height: 8),
            // â”€â”€ Menu Preferensi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildSectionLabel('Preferensi'),
            _buildMenuItem(
              icon: Icons.brightness_6_rounded,
              title: 'Mode Tampilan',
              trailingText: theme.isDarkMode ? 'ðŸŒ™ Gelap' : 'â˜€ï¸ Terang',
              onTap: () => _showThemeDialog(context, theme),
            ),
            _buildMenuItem(
              icon: Icons.language_rounded,
              title: 'Bahasa',
              trailingText: 'ðŸ‡®ðŸ‡© Indonesia',
              onTap: () => _showLanguageDialog(context),
            ),

            const SizedBox(height: 8),
            // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
              ),
              child: ListTile(
                onTap: () => _showLogoutConfirm(context, auth),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppTheme.error, size: 18),
                ),
                title: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.error, size: 18),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
      ),
    );
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(trailingText,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11.5)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 17),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Edit Profil â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');
    bool isLoading = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          actionsAlignment: MainAxisAlignment.center,
          title: const Text('Edit Informasi Akun',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap', hintText: 'Masukkan nama...')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp', hintText: '0812...')),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        final ok = await auth.updateProfile(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim());
                        setState(() => isLoading = false);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Profil berhasil diperbarui!'
                                  : (auth.error ??
                                      'Gagal memperbarui profil.'))));
                        }
                      },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Redeem Kupon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showRedeemCouponDialog(BuildContext context, AuthProvider auth) {
    final codeCtrl = TextEditingController();
    bool isLoading = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          actionsAlignment: MainAxisAlignment.center,
          title: const Text('Redeem Kupon & Voucher',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Masukkan kode kupon voucher untuk menambah saldo token kamu.',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Kode Voucher', hintText: 'misal: PINTAR2026'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) return;
                      setState(() => isLoading = true);
                      final ok = await auth.redeemCoupon(code);
                      setState(() => isLoading = false);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Voucher berhasil di-redeem! Token bertambah.'
                                : (auth.error ??
                                    'Kode voucher tidak valid.'))));
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Redeem'),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Keamanan & Password â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showSecurityDialog(BuildContext context, AuthProvider auth) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isLoading = false;
    int tab = 0; // 0 = Ubah Password, 1 = Reset Password

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          actionsAlignment: MainAxisAlignment.center,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Keamanan & Password',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              tab == 0 ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: tab == 0
                                  ? AppTheme.primary
                                  : AppTheme.borderLight),
                        ),
                        child: Text('Ubah Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: tab == 0
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              tab == 1 ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: tab == 1
                                  ? AppTheme.primary
                                  : AppTheme.borderLight),
                        ),
                        child: Text('Reset Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: tab == 1
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: tab == 0
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: oldPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password Saat Ini')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Password Baru')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Konfirmasi Password')),
                ])
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                          'Link reset password akan dikirimkan ke:\n${auth.user?.email ?? 'email terdaftar'}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                              height: 1.4)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Silakan cek inbox email kamu setelah mengirim link reset.',
                                  style: TextStyle(
                                      color: AppTheme.primary, fontSize: 11))),
                        ]),
                      ),
                    ]),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (tab == 0) {
                          if (newPassCtrl.text != confirmPassCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text(
                                    'Password baru dan konfirmasi tidak cocok.')));
                            return;
                          }
                          setState(() => isLoading = true);
                          final ok = await auth.changePassword(
                              oldPassword: oldPassCtrl.text,
                              newPassword: newPassCtrl.text);
                          setState(() => isLoading = false);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok
                                    ? 'Password berhasil diubah!'
                                    : (auth.error ??
                                        'Gagal mengubah password.'))));
                          }
                        } else {
                          setState(() => isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 800));
                          setState(() => isLoading = false);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Link reset password dikirim ke ${auth.user?.email ?? 'email'}. Cek inbox kamu.')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(tab == 0 ? 'Simpan' : 'Kirim Link'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Membership â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showMembershipDialog(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Paket & Membership',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.user?.activePlanName ?? 'Free Plan',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Saldo Token: ${auth.tokenBalance}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Keuntungan Paket:',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5)),
            const SizedBox(height: 6),
            const Text(
                'â€¢ AI Chat (GPT-4o, Gemini, Claude, DeepSeek, Qwen)\nâ€¢ AI Writer + Storage 500MB\nâ€¢ Paraphrase AI & Plagiarism Check\nâ€¢ Prioritas akses model terbaru',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.6)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.push('/plans');
            },
            child: const Text('Upgrade Paket'),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Tema â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showThemeDialog(BuildContext context, ThemeProvider theme) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Mode Tampilan',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, dialogCtx, theme,
                'â˜€ï¸  Mode Terang (Light)', ThemeMode.light, !theme.isDarkMode),
            const SizedBox(height: 6),
            _buildThemeOption(context, dialogCtx, theme,
                'ðŸŒ™  Mode Gelap (Dark)', ThemeMode.dark, theme.isDarkMode),
          ],
        ),
      ),
    );
  }

  static Widget _buildThemeOption(BuildContext context, BuildContext dialogCtx,
      ThemeProvider theme, String label, ThemeMode mode, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        theme.setThemeMode(mode);
        Navigator.pop(dialogCtx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color:
                            selected ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal))),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 18),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Bahasa â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Pilih Bahasa',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('ðŸ‡®ðŸ‡©', style: TextStyle(fontSize: 22)),
              title: const Text('Bahasa Indonesia',
                  style: TextStyle(color: AppTheme.textPrimary)),
              trailing: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 18),
              onTap: () => Navigator.pop(dialogCtx),
            ),
            ListTile(
              leading: const Text('ðŸ‡ºðŸ‡¸', style: TextStyle(fontSize: 22)),
              title: const Text('English (US)',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('English language will be available soon.')));
              },
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        actionsAlignment: MainAxisAlignment.center,
        title: const Text('Keluar dari akun?',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
            'Kamu perlu login kembali untuk mengakses PintarAja.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await auth.logout();
              if (context.mounted) context.go('/auth/login');
            },
            child: const Text('Keluar',
                style: TextStyle(
                    color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


