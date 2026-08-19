import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _emailSent = false;
  String _submittedEmail = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onReset() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      FocusScope.of(context).unfocus();

      final email = _emailController.text.trim();
      final success = await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(email);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        setState(() {
          _emailSent = true;
          _submittedEmail = email;
        });
      } else {
        final error = ref.read(authControllerProvider).errorMessage ??
            'Unable to process password reset. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(error)),
              ],
            ),
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

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor(context)),
          tooltip: 'Back to Sign In',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
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
            child: _emailSent
                ? _buildSuccessView(context)
                : _buildResetForm(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── App Brand Logo ──
          const Center(
            child: AppLogo(
              size: 44,
              subtitle: 'PASSWORD RECOVERY',
            ),
          ),
          const SizedBox(height: 24),

          // ── Header ──
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the email address associated with your enterprise account. We will send you instructions to reset your password.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mutedText(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // ── Email Input ──
          Text(
            'Email Address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !isLoading,
            onFieldSubmitted: (_) => _onReset(),
            decoration: InputDecoration(
              hintText: 'name@company.com',
              hintStyle: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.outline,
                size: 20,
              ),
              suffixIcon: _emailController.text.isNotEmpty && !isLoading
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Clear email',
                      onPressed: () {
                        _emailController.clear();
                        setState(() {});
                      },
                    )
                  : null,
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
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'Please enter your email address.';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Submit Button ──
          ElevatedButton(
            onPressed: isLoading ? null : _onReset,
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
                        'Sending Reset Link...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Send Reset Link',
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
              onPressed: isLoading
                  ? null
                  : () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/login');
                      }
                    },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Sign In'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'If an account is associated with $_submittedEmail, you will receive instructions to reset your password shortly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mutedText(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Return to Sign In',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
