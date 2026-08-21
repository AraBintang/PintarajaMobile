// ============================================================
// PINTARAJA — FORGOT PASSWORD SCREEN
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../data/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.instance.post(
        ApiConstants.forgotPassword,
        {
          'email': _emailController.text.trim(),
        },
        useAuth: false,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Instruksi reset password telah dikirim ke email.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -130,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // BACK
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          context.go('/auth/login');
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // LOGO
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/pintaraja.webp',
                          width: 38,
                          height: 38,
                        ),
                        Transform.translate(
                          offset: const Offset(-2, 2),
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

                    const SizedBox(height: 26),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.88,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reset your password',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your email and we will send you instructions to reset your password.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'Email',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Email wajib diisi';
                                }

                                if (!email.contains('@')) {
                                  return 'Format email tidak valid';
                                }

                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (!_loading) {
                                  _handleForgotPassword();
                                }
                              },
                              decoration: const InputDecoration(
                                hintText: 'you@example.com',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _loading ? null : _handleForgotPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                ),
                                child: _loading
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
                                        'Send reset instructions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  context.go(
                                    '/auth/login',
                                  );
                                },
                                child: const Text(
                                  'Back to sign in',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
