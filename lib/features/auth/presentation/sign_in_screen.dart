import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;

  Future<void> _signIn(AuthProvider provider) async {
    setState(() => _loading = true);
    await ref.read(currentUserProvider.notifier).signIn(provider);
    if (!mounted) return;
    setState(() => _loading = false);
    context.go(AppRoutes.feed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Sign in to ${AppConstants.appName}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pick a sign-in method. We never spam or sell your data.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.huge),
                _AuthButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Continue with Google',
                  onTap: _loading ? null : () => _signIn(AuthProvider.google),
                  primary: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _AuthButton(
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  onTap: _loading ? null : () => _signIn(AuthProvider.apple),
                ),
                const SizedBox(height: AppSpacing.md),
                _AuthButton(
                  icon: Icons.code_rounded,
                  label: 'Continue with GitHub',
                  onTap: _loading ? null : () => _signIn(AuthProvider.github),
                ),
                const SizedBox(height: AppSpacing.md),
                _AuthButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Continue with Email',
                  onTap: _loading ? null : () => _signIn(AuthProvider.email),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextButton(
                  onPressed: () => context.go(AppRoutes.feed),
                  child: const Text('Skip — browse as guest'),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall,
                    children: const [
                      TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' and '),
                      TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _AuthButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = primary
        ? AppColors.brandPrimary
        : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface);
    final fg = primary
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: primary
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
