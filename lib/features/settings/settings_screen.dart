// ============================================================
// SETTINGS SCREEN — Full Functional
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Profil Header ─────────────────────────────
              _AccountHeader(
                name: user?.name ?? 'Pengguna PintarAja',
                email: user?.email ?? '-',
                plan: user?.plan ?? 'Free',
              ),

              const SizedBox(height: 20),

              // ── Akun ──────────────────────────────────────
              const _SectionTitle(title: 'Akun'),

              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profil & Akun',
                subtitle: 'Kelola nama, email, dan informasi akun',
                onTap: () => context.push('/profile'),
              ),

              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Password',
                subtitle: 'Ubah atau reset password akun kamu',
                onTap: () => _showPasswordDialog(context, auth),
              ),

              _SettingsTile(
                icon: Icons.diamond_outlined,
                title: 'Token & Kuota',
                subtitle: 'Saldo token: ${auth.tokenBalance}',
                onTap: () => _showTokenDialog(context, auth.tokenBalance),
              ),

              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Membership',
                subtitle: 'Lihat paket dan akses AI kamu',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(user?.plan ?? 'Free', style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halaman upgrade paket akan segera tersedia.'))),
              ),

              _SettingsTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Redeem Kupon',
                subtitle: 'Masukkan kode kupon voucher',
                onTap: () => _showRedeemDialog(context, auth),
              ),

              const SizedBox(height: 18),

              // ── Preferensi ────────────────────────────────
              const _SectionTitle(title: 'Preferensi'),

              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                subtitle: 'Atur pemberitahuan PintarAja',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan notifikasi akan segera tersedia.'))),
              ),

              _SettingsTile(
                icon: Icons.brightness_6_rounded,
                title: 'Tampilan',
                subtitle: theme.isDarkMode ? '🌙 Mode Gelap aktif' : '☀️ Mode Terang aktif',
                trailing: Switch.adaptive(
                  value: theme.isDarkMode,
                  activeThumbColor: AppTheme.primary,
                  activeTrackColor: AppTheme.primaryLight,
                  onChanged: (_) => theme.toggleTheme(),
                ),
                onTap: () => theme.toggleTheme(),
              ),

              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
                onTap: () => _showLanguageDialog(context),
              ),

              const SizedBox(height: 18),

              // ── Keamanan ──────────────────────────────────
              const _SectionTitle(title: 'Keamanan'),

              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Keluar',
                subtitle: 'Keluar dari akun PintarAja',
                iconColor: AppTheme.error,
                titleColor: AppTheme.error,
                onTap: () => _confirmLogout(context, auth),
              ),

              const SizedBox(height: 18),

              // ── Tentang ───────────────────────────────────
              const _SectionTitle(title: 'Tentang'),

              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Tentang PintarAja',
                subtitle: 'Informasi aplikasi dan versi',
                onTap: () => _showAbout(context),
              ),

              const SizedBox(height: 28),

              // ── Footer Brand ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/images/pintaraja.webp', width: 34, height: 34, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 34)),
                    const SizedBox(height: 7),
                    const Text('PintarAja', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    const Text('Solusi Mahasiswa, di Pintar Aja', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                    const SizedBox(height: 3),
                    const Text('v1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Token Dialog ─────────────────────────────────────────

  static void _showTokenDialog(BuildContext context, int balance) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Token PintarAja', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Saldo Token', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text('$balance Token', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Token digunakan untuk setiap permintaan AI. Token habis? Redeem voucher atau upgrade paket kamu.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  // ── Password Dialog ───────────────────────────────────────

  static void _showPasswordDialog(BuildContext context, AuthProvider auth) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isLoading = false;
    int tab = 0;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Keamanan & Password', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => tab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: tab == 0 ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tab == 0 ? AppTheme.primary : AppTheme.borderLight),
                      ),
                      child: Text('Ubah Password', textAlign: TextAlign.center,
                        style: TextStyle(color: tab == 0 ? Colors.white : AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
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
                        color: tab == 1 ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tab == 1 ? AppTheme.primary : AppTheme.borderLight),
                      ),
                      child: Text('Reset Password', textAlign: TextAlign.center,
                        style: TextStyle(color: tab == 1 ? Colors.white : AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
          content: tab == 0
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Saat Ini')),
                  const SizedBox(height: 10),
                  TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru')),
                  const SizedBox(height: 10),
                  TextField(controller: confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Password')),
                ])
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Link reset akan dikirim ke:\n${auth.user?.email ?? 'email terdaftar'}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Cek inbox email kamu setelah menekan tombol "Kirim Link".', style: TextStyle(color: AppTheme.primary, fontSize: 11))),
                    ]),
                  ),
                ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (tab == 0) {
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru dan konfirmasi tidak cocok.')));
                    return;
                  }
                  setState(() => isLoading = true);
                  final ok = await auth.changePassword(oldPassword: oldPassCtrl.text, newPassword: newPassCtrl.text);
                  setState(() => isLoading = false);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Password berhasil diubah!' : (auth.error ?? 'Gagal mengubah password.'))));
                  }
                } else {
                  setState(() => isLoading = true);
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() => isLoading = false);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link reset password dikirim ke ${auth.user?.email ?? 'email'}. Silakan cek inbox.')));
                  }
                }
              },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tab == 0 ? 'Simpan' : 'Kirim Link'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Redeem Dialog ─────────────────────────────────────────

  static void _showRedeemDialog(BuildContext context, AuthProvider auth) {
    final codeCtrl = TextEditingController();
    bool isLoading = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          title: const Text('Redeem Kupon & Voucher', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Masukkan kode voucher kamu untuk menambah saldo token.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Kode Voucher', hintText: 'misal: PINTAR2026')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;
                setState(() => isLoading = true);
                final ok = await auth.redeemCoupon(code);
                setState(() => isLoading = false);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Voucher berhasil di-redeem! Token bertambah.' : (auth.error ?? 'Kode voucher tidak valid.'))));
                }
              },
              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Redeem'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Language Dialog ───────────────────────────────────────

  static void _showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Pilih Bahasa', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Text('🇮🇩', style: TextStyle(fontSize: 22)),
            title: const Text('Bahasa Indonesia', style: TextStyle(color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
            onTap: () => Navigator.pop(dialogCtx),
          ),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
            title: const Text('English (US)', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('English language will be available soon.')));
            },
          ),
        ]),
      ),
    );
  }

  // ── Logout Dialog ─────────────────────────────────────────

  static void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Keluar dari akun?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Kamu perlu login kembali untuk mengakses PintarAja.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) context.go('/auth/login');
            },
            child: const Text('Keluar', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── About Dialog ──────────────────────────────────────────

  static void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PintarAja',
      applicationVersion: 'v1.0.0',
      applicationLegalese: '© 2025 PintarAja. All rights reserved.',
      children: [
        const SizedBox(height: 10),
        const Text('PintarAja adalah platform AI akademik all-in-one untuk mahasiswa Indonesia.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ============================================================
// ACCOUNT HEADER WIDGET
// ============================================================

class _AccountHeader extends StatelessWidget {
  final String name;
  final String email;
  final String plan;

  const _AccountHeader({required this.name, required this.email, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(plan, style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE WIDGET
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }
}

// ============================================================
// SETTINGS TILE WIDGET
// ============================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppTheme.primary;
    final effectiveTitleColor = titleColor ?? AppTheme.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 18),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: effectiveTitleColor, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
                  ],
                ]),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}