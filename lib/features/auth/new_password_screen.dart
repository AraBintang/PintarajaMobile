// ============================================================
// PINTARAJA — NEW PASSWORD SCREEN
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.instance.post(
        ApiConstants.newPassword,
        {
          'email': widget.email,
          'token': widget.token,
          'password': _passwordController.text,
        },
        useAuth: false,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Password berhasil diubah',
            ),
            content: const Text(
              'Password kamu sudah berhasil diperbarui. Silakan login kembali.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Login',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      context.go('/auth/login');
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terjadi kesalahan saat mengubah password.',
          ),
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  24,
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
                      'Create new password',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Buat password baru untuk ${widget.email}.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    const Text(
                      'New password',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        final password = value ?? '';

                        if (password.isEmpty) {
                          return 'Password wajib diisi';
                        }

                        if (password.length < 8) {
                          return 'Password minimal 8 karakter';
                        }

                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Minimal 8 karakter',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    const Text(
                      'Confirm password',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }

                        if (value != _passwordController.text) {
                          return 'Password tidak sama';
                        }

                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Ulangi password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: _loading
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
                                'Change password',
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.go(
                            '/auth/login',
                          );
                        },
                        child: const Text(
                          'Back to login',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
