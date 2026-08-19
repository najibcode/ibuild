import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Calculate password strength (0: Weak, 1: Medium, 2: Strong)
  int _calculatePasswordStrength(String password) {
    if (password.length < 6) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password) || RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      score++;
    }
    return score; // 0: Weak, 1: Medium, 2: Strong
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 2:
        return 'Strong';
      case 1:
        return 'Medium';
      default:
        return 'Weak';
    }
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 2:
        return const Color(0xFF10B981); // Emerald
      case 1:
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFFEF4444); // Red
    }
  }

  void _onUpdatePassword() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);
      FocusScope.of(context).unfocus();

      final success = await ref
          .read(authControllerProvider.notifier)
          .updatePassword(_newPasswordController.text);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Password updated successfully! Please sign in.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      } else {
        final error = ref.read(authControllerProvider).errorMessage ??
            'Unable to update password. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = _isSubmitting || state.isLoading;
    final newPassword = _newPasswordController.text;
    final strength = _calculatePasswordStrength(newPassword);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ──
                  const Center(
                    child: AppLogo(
                      size: 44,
                      subtitle: 'SET NEW PASSWORD',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Header ──
                  Text(
                    'Set New Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a strong password to secure your enterprise ERP account.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── New Password ──
                  Text(
                    'New Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      hintStyle: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.outline,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.outline,
                          size: 20,
                        ),
                        tooltip: _obscureNewPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your new password.';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),

                  // ── Password Strength Bar ──
                  if (newPassword.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (strength + 1) / 3.0,
                            backgroundColor: AppColors.border(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _strengthColor(strength),
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _strengthLabel(strength),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _strengthColor(strength),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Confirm Password ──
                  Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Confirm new password',
                      hintStyle: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_reset,
                        color: AppColors.outline,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.outline,
                          size: 20,
                        ),
                        tooltip: _obscureConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      if (val != _newPasswordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Submit Button ──
                  ElevatedButton(
                    onPressed: isLoading ? null : _onUpdatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Updating Password...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ── Return to Sign In ──
                  Center(
                    child: TextButton.icon(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Sign In'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.mutedText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
