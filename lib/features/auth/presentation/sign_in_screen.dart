import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(currentUserProvider.notifier).signIn(AuthProvider.google);
      if (mounted) context.go(AppRoutes.feed);
    } catch (e) {
      setState(() => _error = 'Google sign-in did not complete. You can retry, or continue without an account and sign in later from your profile.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    await ref.read(currentUserProvider.notifier).continueAsGuest();
    if (mounted) context.go(AppRoutes.feed);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            const Center(child: DoodleFigure(Figure.selfie, hue: AppColors.accent, height: 190, semanticLabel: 'Person taking a selfie')),
            const SizedBox(height: AppSpacing.lg),
            Text('Keep your feed\non every device.', style: t.displayMedium),
            const SizedBox(height: AppSpacing.md),
            Text('An account syncs saved stories, interests, and your digest schedule. Reading does not need one.', style: t.bodyLarge),
            const Spacer(),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                ),
                child: Text(_error!, style: t.bodyMedium?.copyWith(color: AppColors.ink)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton.icon(
              onPressed: _busy ? null : _google,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent))
                  : const Icon(AppIcons.signIn, size: 18),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: _busy ? null : _guest, child: const Text('Continue without an account')),
            const SizedBox(height: AppSpacing.lg),
            Center(child: Text('No passwords. No newsletters.', style: AppTypography.kicker())),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
