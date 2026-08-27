// ============================================================
// PINTARAJA â€” LOGIN SCREEN
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  bool _rememberMe = false;

  bool _showSuccessPopup = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      remember: _rememberMe,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        auth.error ?? 'Email atau password salah.',
      );

      return;
    }

    await _showSuccessDialog(
      title: 'Login berhasil',
      message: 'Selamat datang kembali di PintarAja.',
    );

    if (!mounted) {
      return;
    }

    context.go('/chat');
  }

  // ==========================================================
  // SUCCESS POPUP
  // ==========================================================

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    if (_showSuccessPopup) {
      return;
    }

    _showSuccessPopup = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _SuccessDialog();
      },
    );

    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    _showSuccessPopup = false;
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  String? _validateEmail(
    String? value,
  ) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi';
    }

    final regex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _validatePassword(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password wajib diisi';
    }

    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final keyboardHeight = MediaQuery.viewInsetsOf(
      context,
    ).bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -120,
            child: _GlowCircle(
              size: 360,
              color: AppTheme.primaryLight.withValues(
                alpha: 0.22,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: _GlowCircle(
              size: 340,
              color: AppTheme.accent.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + keyboardHeight,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // LOGO
                    // ==================================================

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/pintaraja.webp',
                          width: 38,
                          height: 38,
                        ),
                        Transform.translate(
                          offset: const Offset(
                            -2,
                            2,
                          ),
                          child: const Text(
                            'intaraja',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    // ==================================================
                    // LOGIN CARD
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.88,
                        ),
                        borderRadius: BorderRadius.circular(
                          24,
                        ),
                        border: Border.all(
                          color: Colors.white,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 30,
                            offset: const Offset(
                              0,
                              12,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          const Text(
                            'Sign in to continue using Pintaraja',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(
                            height: 26,
                          ),
                          const _FieldLabel(
                            text: 'Email',
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateEmail,
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 18,
                          ),
                          const _FieldLabel(
                            text: 'Password',
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) {
                              _handleLogin();
                            },
                            decoration: InputDecoration(
                              hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () {
                                      _obscurePassword = !_obscurePassword;
                                    },
                                  );
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppTheme.primary,
                                      onChanged: (value) {
                                        setState(
                                          () {
                                            _rememberMe = value ?? false;
                                          },
                                        );
                                      },
                                    ),
                                    const Flexible(
                                      child: Text(
                                        'Remember me',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go(
                                    '/auth/forgot-password',
                                  );
                                },
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(
                                      0xFFF59E0B,
                                    ),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          Consumer<AuthProvider>(
                            builder: (
                              context,
                              auth,
                              _,
                            ) {
                              return SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      auth.isLoading ? null : _handleLogin,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Sign in',
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () async {
                                final auth = context.read<AuthProvider>();
                                try {
                                  final googleSignIn = GoogleSignIn();
                                  await googleSignIn.signOut();
                                  final googleUser =
                                      await googleSignIn.signIn();
                                  if (googleUser == null)
                                    return; // user cancelled
                                  final googleAuth =
                                      await googleUser.authentication;
                                  final idToken = googleAuth.idToken;
                                  final accessToken = googleAuth.accessToken;
                                  final success = await auth.loginWithGoogle(
                                    googleToken: idToken,
                                    accessToken: accessToken,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    context.go('/chat');
                                  } else {
                                    _showError(auth.error ??
                                        'Login dengan Google tidak dapat diproses saat ini.');
                                  }
                                } catch (e) {
                                  _showError(
                                      'Gagal memulai login Google. Pastikan koneksi internet Anda aktif.');
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/pintaraja.png',
                                    height: 20,
                                    width: 20,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Continue with Google'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 22,
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                context.go(
                                  '/auth/register',
                                );
                              },
                              child: const Text(
                                "Don't have an account? Create one",
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'PintarAja â€” Platform AI untuk mahasiswa Indonesia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUCCESS DIALOG
// ============================================================

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                24,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.10,
                  ),
                  blurRadius: 30,
                  offset: const Offset(
                    0,
                    15,
                  ),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.success,
                    size: 38,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                const Text(
                  'Mengalihkan ke PintarAja Chat...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

