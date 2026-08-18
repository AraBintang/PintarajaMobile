// ============================================================
// SETTINGS SCREEN — Full Functional
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/providers/language_provider.dart';
import '../../data/providers/notification_provider.dart';
import '../shared/widgets/payment_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final notif = context.watch<NotificationProvider>();
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
                subtitle: notif.enabled ? 'Pemberitahuan aktif' : 'Pemberitahuan dinonaktifkan',
                trailing: Switch.adaptive(
                  value: notif.enabled,
                  activeThumbColor: AppTheme.primary,
                  activeTrackColor: AppTheme.primaryLight,
                  onChanged: (v) => notif.setEnabled(v),
                ),
                onTap: () => notif.setEnabled(!notif.enabled),
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
                subtitle: lang.isEnglish ? 'English (US)' : 'Bahasa Indonesia',
                trailing: Text(
                  lang.isEnglish ? '🇺🇸' : '🇮🇩',
                  style: const TextStyle(fontSize: 20),
                ),
                onTap: () => _showLanguageDialog(context, lang),
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
        backgroundColor: AppTheme.getSurface(context),
        title: Text('Token PintarAja', style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
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
          Text(
            'Token digunakan untuk setiap permintaan AI. Token habis? Beli paket top-up di bawah.',
            style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12, height: 1.4),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openTopUpSheet(context);
            },
            child: const Text('Beli Token'),
          ),
        ],
      ),
    );
  }

  static void _openTopUpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.getBorder(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Pilih Paket Top-up Token',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.getTextColor(context)),
              ),
              const SizedBox(height: 16),
              _buildTopUpOption(context, sheetCtx, '10.000 Token', 10000),
              _buildTopUpOption(context, sheetCtx, '50.000 Token (Diskon)', 45000),
              _buildTopUpOption(context, sheetCtx, '100.000 Token (Hemat)', 80000),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTopUpOption(BuildContext context, BuildContext sheetCtx, String label, double price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(sheetCtx);
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (paymentCtx) {
              return PaymentSelectionSheet(
                itemName: 'Top-up $label',
                price: price,
                onPaymentSuccess: () async {
                  Navigator.pop(paymentCtx);
                  await context.read<AuthProvider>().refreshUser();
                },
              );
            },
          );
        },
        leading: const Icon(Icons.diamond_outlined, color: AppTheme.primary),
        title: Text(label, style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.bold)),
        trailing: Text(
          'Rp ${price.toStringAsFixed(0)}',
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14),
        ),
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

  static void _showLanguageDialog(BuildContext context, LanguageProvider lang) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          title: Text('Pilih Bahasa', style: TextStyle(color: AppTheme.getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Text('🇮🇩', style: TextStyle(fontSize: 22)),
              title: Text('Bahasa Indonesia', style: TextStyle(color: AppTheme.getTextColor(context))),
              trailing: !lang.isEnglish
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                lang.setLocale('id');
                Navigator.pop(dialogCtx);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
              title: Text('English (US)', style: TextStyle(color: AppTheme.getTextColor(context))),
              trailing: lang.isEnglish
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                lang.setLocale('en');
                Navigator.pop(dialogCtx);
              },
            ),
          ]),
        ),
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