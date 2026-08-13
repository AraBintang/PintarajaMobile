import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundApp,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AccountHeader(
                name:
                    user?.name ?? 'Pengguna PintarAja',
                email:
                    user?.email ?? '-',
                plan:
                    user?.plan ?? 'Free',
              ),

              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'Akun',
              ),

              _SettingsTile(
                icon:
                    Icons.person_outline_rounded,
                title:
                    'Profil & akun',
                subtitle:
                    'Kelola nama, email, dan informasi akun',
                onTap: () {
                  context.push('/profile');
                },
              ),

              _SettingsTile(
                icon:
                    Icons.workspace_premium_outlined,
                title:
                    'Membership',
                subtitle:
                    'Lihat paket dan akses AI kamu',
                onTap: () {
                  _showMessage(
                    context,
                    'Halaman Membership akan kita sambungkan ke backend.',
                  );
                },
              ),

              _SettingsTile(
                icon:
                    Icons.diamond_outlined,
                title:
                    'Token & kuota',
                subtitle:
                    'Saldo token: ${auth.tokenBalance}',
                onTap: () {
                  _showTokenDialog(
                    context,
                    auth.tokenBalance,
                  );
                },
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Preferensi',
              ),

              _SettingsTile(
                icon:
                    Icons.notifications_none_rounded,
                title:
                    'Notifikasi',
                subtitle:
                    'Atur pemberitahuan PintarAja',
                onTap: () {
                  _showMessage(
                    context,
                    'Pengaturan notifikasi akan kita sambungkan berikutnya.',
                  );
                },
              ),

              _SettingsTile(
                icon:
                    Icons.palette_outlined,
                title:
                    'Tampilan',
                subtitle:
                    'Tema dan tampilan aplikasi',
                onTap: () {
                  _showMessage(
                    context,
                    'Pengaturan tampilan akan kita sambungkan berikutnya.',
                  );
                },
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Keamanan',
              ),

              _SettingsTile(
                icon:
                    Icons.lock_outline_rounded,
                title:
                    'Password',
                subtitle:
                    'Ubah password akun PintarAja',
                onTap: () {
                  _showMessage(
                    context,
                    'Halaman ubah password akan kita sambungkan ke API.',
                  );
                },
              ),

              _SettingsTile(
                icon:
                    Icons.logout_rounded,
                title:
                    'Keluar',
                subtitle:
                    'Keluar dari akun PintarAja',
                iconColor:
                    AppTheme.error,
                titleColor:
                    AppTheme.error,
                onTap: () {
                  _confirmLogout(
                    context,
                  );
                },
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Tentang',
              ),

              _SettingsTile(
                icon:
                    Icons.info_outline_rounded,
                title:
                    'Tentang PintarAja',
                subtitle:
                    'Informasi aplikasi dan versi',
                onTap: () {
                  _showAbout(
                    context,
                  );
                },
              ),

              const SizedBox(height: 28),

              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/pintaraja.webp',
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'PintarAja',
                      style: TextStyle(
                        color:
                            AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Solusi Mahasiswa, di Pintar Aja',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TOKEN
  // ==========================================================

  static void _showTokenDialog(
    BuildContext context,
    int balance,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              AppTheme.surfaceLight,
          title: const Text(
            'Token & Kuota',
            style: TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF59E0B,
                  ).withValues(
                    alpha: 0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color:
                      Color(0xFFF59E0B),
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$balance',
                style: const TextStyle(
                  color:
                      AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Token tersedia',
                style: TextStyle(
                  color:
                      AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  static Future<void> _confirmLogout(
    BuildContext context,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.surfaceLight,
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: const Text(
            'Kamu perlu login kembali untuk mengakses PintarAja.',
            style: TextStyle(
              color:
                  AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color:
                      AppTheme.error,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await context
        .read<AuthProvider>()
        .logout();

    if (!context.mounted) {
      return;
    }

    context.go(
      '/auth/login',
    );
  }

  // ==========================================================
  // ABOUT
  // ==========================================================

  static void _showAbout(
    BuildContext context,
  ) {
    showAboutDialog(
      context: context,
      applicationName:
          'PintarAja',
      applicationVersion:
          'Mobile',
      applicationIcon:
          Image.asset(
        'assets/images/pintaraja.webp',
        width: 42,
        height: 42,
      ),
      children: const [
        SizedBox(height: 10),
        Text(
          'Platform AI untuk membantu mahasiswa Indonesia dalam belajar, riset, menulis, dan berbagai kebutuhan akademik.',
        ),
      ],
    );
  }

  // ==========================================================
  // INFO
  // ==========================================================

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}

// ============================================================
// ACCOUNT HEADER
// ============================================================

class _AccountHeader
    extends StatelessWidget {
  final String name;
  final String email;
  final String plan;

  const _AccountHeader({
    required this.name,
    required this.email,
    required this.plan,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final cleanName =
        name.trim();

    final initial =
        cleanName.isEmpty
            ? '?'
            : cleanName
                .substring(
                  0,
                  1,
                )
                .toUpperCase();

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.surfaceLight,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppTheme.borderLight,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                54,
            height:
                54,
            decoration:
                BoxDecoration(
              color:
                  AppTheme
                      .primary
                      .withValues(
                alpha:
                    0.10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                Center(
              child:
                  Text(
                initial,
                style:
                    const TextStyle(
                  color:
                      AppTheme
                          .primary,
                  fontSize:
                      22,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .textPrimary,
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  email,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .textSecondary,
                    fontSize:
                        11,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        8,
                    vertical:
                        3,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppTheme
                            .primary
                            .withValues(
                      alpha:
                          0.10,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child:
                      Text(
                    plan,
                    maxLines:
                        1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          AppTheme
                              .primary,
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons
                .chevron_right_rounded,
            color:
                AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets
              .fromLTRB(
        5,
        0,
        5,
        7,
      ),
      child:
          Text(
        title,
        style:
            const TextStyle(
          color:
              AppTheme.textMuted,
          fontSize:
              11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS TILE
// ============================================================

class _SettingsTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final actualIconColor =
        iconColor ??
            AppTheme.textSecondary;

    final actualTitleColor =
        titleColor ??
            AppTheme.textPrimary;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 2,
      ),
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child:
            InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          child:
              Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  13,
              vertical:
                  12,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppTheme
                      .surfaceLight,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border:
                  Border.all(
                color:
                    AppTheme
                        .borderLight,
              ),
            ),
            child:
                Row(
              children: [
                Container(
                  width:
                      40,
                  height:
                      40,
                  decoration:
                      BoxDecoration(
                    color:
                        actualIconColor
                            .withValues(
                      alpha:
                          0.10,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      11,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color:
                        actualIconColor,
                    size:
                        21,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        title,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color:
                              actualTitleColor,
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        subtitle,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .textSecondary,
                          fontSize:
                              10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      AppTheme.textMuted,
                  size:
                      19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}