// ============================================================
// PINTARAJA — REGISTER + OTP SCREEN
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'turnstile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ==========================================================
  // FORM
  // ==========================================================

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  final _referralController = TextEditingController();

  // ==========================================================
  // OTP
  // ==========================================================

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  // ==========================================================
  // STATE
  // ==========================================================

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  bool _isOtpStep = false;

  int _resendCooldown = 0;

  Timer? _resendTimer;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();

    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }

    _resendTimer?.cancel();

    super.dispose();
  }

  // ==========================================================
  // REGISTER
  // ==========================================================

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(
        'Password dan konfirmasi password tidak cocok.',
      );

      return;
    }

    // ========================================================
    // TURNSTILE
    // ========================================================

    final turnstileToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const TurnstileScreen(
          siteKey: '0x4AAAAAACr3b_AwhmbkxsbO',
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (turnstileToken == null || turnstileToken.isEmpty) {
      _showError(
        'Verifikasi keamanan diperlukan.',
      );

      return;
    }

    // ========================================================
    // REGISTER
    // ========================================================

    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      referralCode: _referralController.text.trim(),
      turnstileToken: turnstileToken,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        auth.error ?? 'Registrasi gagal.',
      );

      return;
    }

    // ========================================================
    // SUCCESS POPUP
    // ========================================================

    await _showSuccessDialog(
      title: 'Registrasi berhasil',
      message: 'Kode OTP telah dikirim ke email kamu.',
    );

    if (!mounted) {
      return;
    }

    // ========================================================
    // MOVE TO OTP
    // ========================================================

    setState(() {
      _isOtpStep = true;
    });

    _clearOtp();

    _startResendCooldown();

    await Future.delayed(
      const Duration(
        milliseconds: 250,
      ),
    );

    if (!mounted) {
      return;
    }

    _otpFocusNodes.first.requestFocus();
  }

  // ==========================================================
  // VERIFY OTP
  // ==========================================================

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _otpControllers
        .map(
          (controller) => controller.text,
        )
        .join();

    if (otp.length != 6) {
      _showError(
        'Masukkan kode OTP lengkap.',
      );

      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.verifyOtp(
      _emailController.text.trim(),
      otp,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _clearOtp();

      _showError(
        auth.error ?? 'Kode OTP tidak valid.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 100,
        ),
      );

      if (mounted) {
        _otpFocusNodes.first.requestFocus();
      }

      return;
    }

    // ========================================================
    // VERIFY SUCCESS POPUP
    // ========================================================

    await _showSuccessDialog(
      title: 'Verifikasi berhasil',
      message: 'Akun kamu sudah aktif. Selamat datang di PintarAja!',
    );

    if (!mounted) {
      return;
    }

    // ========================================================
    // GO TO CHAT
    // ========================================================

    context.go('/chat');
  }

  // ==========================================================
  // RESEND OTP
  // ==========================================================

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.resendOtp(
      _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        auth.error ?? 'Gagal mengirim ulang OTP.',
      );

      return;
    }

    _clearOtp();

    _startResendCooldown();

    _otpFocusNodes.first.requestFocus();

    _showSuccessSnackBar(
      'Kode OTP baru telah dikirim.',
    );
  }

  // ==========================================================
  // OTP INPUT
  // ==========================================================

  void _handleOtpChanged(
    int index,
    String value,
  ) {
    final digits = value.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (digits.isEmpty) {
      setState(() {});
      return;
    }

    // ========================================================
    // PASTE
    // ========================================================

    if (digits.length > 1) {
      _fillOtpFromString(
        digits,
      );

      return;
    }

    // ========================================================
    // NORMAL INPUT
    // ========================================================

    _otpControllers[index].text = digits.substring(
      0,
      1,
    );

    _otpControllers[index].selection = TextSelection.fromPosition(
      TextPosition(
        offset: _otpControllers[index].text.length,
      ),
    );

    if (index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }

    setState(() {});
  }

  // ==========================================================
  // OTP KEYBOARD
  // ==========================================================

  void _handleOtpKeyEvent(
    int index,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return;
    }

    // BACKSPACE
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _otpControllers[index - 1].clear();

      _otpFocusNodes[index - 1].requestFocus();

      return;
    }

    // ENTER
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _handleVerifyOtp();
    }
  }

  // ==========================================================
  // FILL OTP
  // ==========================================================

  void _fillOtpFromString(
    String value,
  ) {
    final digits = value.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (digits.isEmpty) {
      return;
    }

    final limited = digits.length > 6
        ? digits.substring(
            0,
            6,
          )
        : digits;

    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = i < limited.length ? limited[i] : '';
    }

    final nextEmptyIndex = _otpControllers.indexWhere(
      (controller) => controller.text.isEmpty,
    );

    if (nextEmptyIndex != -1) {
      _otpFocusNodes[nextEmptyIndex].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }

    setState(() {});
  }

  // ==========================================================
  // CLEAR OTP
  // ==========================================================

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }

    setState(() {});
  }

  // ==========================================================
  // RESEND COOLDOWN
  // ==========================================================

  void _startResendCooldown() {
    _resendTimer?.cancel();

    setState(() {
      _resendCooldown = 60;
    });

    _resendTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendCooldown <= 1) {
          timer.cancel();

          setState(() {
            _resendCooldown = 0;
          });

          return;
        }

        setState(() {
          _resendCooldown--;
        });
      },
    );
  }

  // ==========================================================
  // BACK
  // ==========================================================

  void _handleBack() {
    if (_isOtpStep) {
      _clearOtp();

      _resendTimer?.cancel();

      setState(() {
        _isOtpStep = false;
        _resendCooldown = 0;
      });

      return;
    }

    context.go(
      '/auth/login',
    );
  }

  // ==========================================================
  // SUCCESS POPUP
  // ==========================================================

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        title: title,
        message: message,
      ),
    );

    await Future.delayed(
      const Duration(
        seconds: 3,
      ),
    );

    if (!mounted) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(
            16,
          ),
          duration: const Duration(
            seconds: 3,
          ),
        ),
      );
  }

  // ==========================================================
  // SUCCESS SNACKBAR
  // ==========================================================

  void _showSuccessSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(
            16,
          ),
        ),
      );
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  String? _validateName(
    String? value,
  ) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Nama wajib diisi';
    }

    if (name.length < 2) {
      return 'Nama terlalu pendek';
    }

    return null;
  }

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

  String? _validateConfirmPassword(
    String? value,
  ) {
    final confirm = value ?? '';

    if (confirm.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (confirm != _passwordController.text) {
      return 'Password tidak sama';
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
              size: 340,
              color: AppTheme.primaryLight.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            right: -140,
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
                12,
                24,
                24 + keyboardHeight,
              ),
              child: Column(
                children: [
                  // ==================================================
                  // BACK
                  // ==================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary,
                      ),
                      tooltip: 'Kembali',
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // ==================================================
                  // LOGO
                  // ==================================================

                  GestureDetector(
                    onTap: () {
                      context.go('/');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/pintaraja.webp',
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
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
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  // ==================================================
                  // CARD
                  // ==================================================

                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    child: _isOtpStep ? _buildOtpCard() : _buildRegisterCard(),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'PintarAja — Platform AI untuk mahasiswa Indonesia',
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
        ],
      ),
    );
  }

  // ==========================================================
  // REGISTER CARD
  // ==========================================================

  Widget _buildRegisterCard() {
    return Container(
      key: const ValueKey(
        'register',
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your account',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Join Pintaraja and start exploring smarter learning',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),

            const SizedBox(
              height: 26,
            ),

            const _FieldLabel(
              text: 'Full name',
            ),

            const SizedBox(
              height: 8,
            ),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: _validateName,
              decoration: const InputDecoration(
                hintText: 'Your full name',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
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
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
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
              height: 18,
            ),

            const _FieldLabel(
              text: 'Confirm password',
            ),

            const SizedBox(
              height: 8,
            ),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.next,
              validator: _validateConfirmPassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      },
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const _FieldLabel(
              text: 'Referral code (optional)',
            ),

            const SizedBox(
              height: 8,
            ),

            TextFormField(
              controller: _referralController,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: 'Enter referral code',
                prefixIcon: Icon(
                  Icons.card_giftcard_outlined,
                  size: 20,
                ),
                counterText: '',
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // CREATE ACCOUNT
            // ==================================================

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
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create account',
                          ),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 20,
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
                    final googleSignIn = GoogleSignIn(
                      scopes: ['email', 'profile'],
                    );
                    await googleSignIn.signOut();
                    final googleUser = await googleSignIn.signIn();
                    if (googleUser == null) return;
                    final googleAuth = await googleUser.authentication;
                    final success = await auth.loginWithGoogle(
                      googleToken: googleAuth.idToken,
                      accessToken: googleAuth.accessToken,
                    );
                    if (!mounted) return;
                    if (success) {
                      context.go('/chat');
                    } else {
                      _showError(auth.error ??
                          'Registrasi/login dengan Google gagal.');
                    }
                  } catch (e) {
                    _showError(kIsWeb
                        ? 'Login Google gagal dijalankan di browser. Pastikan google-signin-client_id sudah diisi di web/index.html dan domain ini terdaftar di Google Cloud Console (Authorized JavaScript origins).'
                        : 'Gagal memulai login Google. Periksa koneksi internet Anda.');
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Sign up with Google'),
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
                    '/auth/login',
                  );
                },
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // OTP CARD
  // ==========================================================

  Widget _buildOtpCard() {
    return Container(
      key: const ValueKey(
        'otp',
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppTheme.primary,
              size: 28,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Verify your email',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            'We sent a 6-digit code to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Kode berlaku selama 5 menit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // ==================================================
          // RESPONSIVE OTP
          // ==================================================

          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              const gap = 6.0;

              final availableWidth = constraints.maxWidth;

              final boxWidth = ((availableWidth - (gap * 5)) / 6).clamp(
                36.0,
                48.0,
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (
                    index,
                  ) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == 5 ? 0 : gap,
                      ),
                      child: SizedBox(
                        width: boxWidth,
                        child: _OtpInputBox(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          onChanged: (
                            value,
                          ) {
                            _handleOtpChanged(
                              index,
                              value,
                            );
                          },
                          onKeyEvent: (
                            event,
                          ) {
                            _handleOtpKeyEvent(
                              index,
                              event,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // VERIFY
          // ==================================================

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
                  onPressed: auth.isLoading ? null : _handleVerifyOtp,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Verify code',
                        ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 20,
          ),

          // ==================================================
          // RESEND
          // ==================================================

          if (_resendCooldown > 0)
            Text(
              'Resend code in ${_resendCooldown}s',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            )
          else
            TextButton.icon(
              onPressed: _handleResendOtp,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text(
                'Resend code',
              ),
            ),

          const SizedBox(
            height: 8,
          ),

          TextButton(
            onPressed: _handleBack,
            child: const Text(
              'Back to registration',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CARD DECORATION
  // ==========================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }
}

// ============================================================
// OTP INPUT BOX
// ============================================================

class _OtpInputBox extends StatefulWidget {
  final TextEditingController controller;

  final FocusNode focusNode;

  final ValueChanged<String> onChanged;

  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpInputBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpInputBox> createState() => _OtpInputBoxState();
}

class _OtpInputBoxState extends State<_OtpInputBox> {
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();

    _keyboardFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height: 52,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: 1,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
              borderSide: const BorderSide(
                color: AppTheme.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUCCESS DIALOG
// ============================================================

class _SuccessDialog extends StatefulWidget {
  final String title;
  final String message;

  const _SuccessDialog({
    required this.title,
    required this.message,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 650,
      ),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
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
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(
              28,
            ),
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
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

// ============================================================
// FIELD LABEL
// ============================================================

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

// ============================================================
// GLOW CIRCLE
// ============================================================

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
