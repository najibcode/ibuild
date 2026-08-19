import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Dismiss soft keyboard
      FocusScope.of(context).unfocus();

      final success = await ref.read(authControllerProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        // Complete autofill context
        TextInput.finishAutofillContext();
        context.go('/dashboard');
      } else {
        final error = ref.read(authControllerProvider).errorMessage ??
            'Unable to sign in. Please check your credentials.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: 24,
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
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
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── App Brand Logo ──
                        const Center(
                          child: AppLogo(
                            size: 48,
                            subtitle: 'ERP MANAGEMENT PORTAL',
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Portal Header ──
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your enterprise credentials to access your workspace.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Email Field ──
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
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          enabled: !isLoading,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocusNode);
                          },
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
                        const SizedBox(height: 20),

                        // ── Password Field Header ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text(context),
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ── Password Field ──
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _onLogin(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: AppColors.mutedText(context),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.outline,
                              size: 20,
                            ),
                            suffixIcon: Semantics(
                              label: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              child: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.outline,
                                  size: 20,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Sign In Action Button ──
                        ElevatedButton(
                          onPressed: isLoading ? null : _onLogin,
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
                                      'Signing In...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // ── Enterprise Notice Footer ──
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bg(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.mutedText(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Don\'t have an account? Contact your system administrator to provision access.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedText(context),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
