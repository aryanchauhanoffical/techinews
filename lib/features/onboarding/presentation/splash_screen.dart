import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/doodles.dart';
import '../../../services/providers.dart';

/// Wordmark, the poster illustration, then either straight into the feed
/// (returning readers, under a second) or the welcome actions (first run).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _welcome = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final done = ref.read(localStoreProvider).onboardingComplete;
      if (done) {
        context.go(AppRoutes.feed);
      } else {
        setState(() => _welcome = true);
      }
    });
  }

  static const _repo = 'https://github.com/aryanchauhanoffical/techinews';
  void _open(String doc) => launchUrl(Uri.parse('$_repo/blob/main/$doc'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final reduced = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth > 700;
            final hero = Image.asset('assets/images/illustration-splash-hero.png', fit: BoxFit.contain, semanticLabel: 'All of tech. In one place. Your hourly digest of the top stories from around the tech world.');
            final actions = AnimatedOpacity(
              duration: Duration(milliseconds: reduced ? 0 : 420),
              curve: Curves.easeOut,
              opacity: _welcome ? 1 : 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _welcome ? () => context.go(AppRoutes.onboarding) : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [Text('Get started'), SizedBox(width: 8), DoodleArrow(color: AppColors.onAccent, width: 20)],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: _welcome ? () => context.push(AppRoutes.signIn) : null,
                    child: const Text('Log back in'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text.rich(
                    TextSpan(
                      text: 'By continuing you agree to our ',
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: AppTypography.sans(12, color: AppColors.accent),
                          recognizer: TapGestureRecognizer()..onTap = () => _open('TERMS.md'),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTypography.sans(12, color: AppColors.accent),
                          recognizer: TapGestureRecognizer()..onTap = () => _open('PRIVACY.md'),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppTypography.sans(12, color: AppColors.inkMuted),
                  ),
                ],
              ),
            );
            final top = Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
              child: Row(
                children: [
                  const Wordmark(size: 30),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Duration(milliseconds: reduced ? 0 : 420),
                    opacity: _welcome ? 1 : 0,
                    child: InkWell(
                      onTap: _welcome ? () => context.push(AppRoutes.signIn) : null,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Already a user?', style: t.bodySmall),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Sign in', style: AppTypography.sans(14, weight: FontWeight.w600, color: AppColors.accent)),
                                const SizedBox(width: 4),
                                const DoodleArrow(color: AppColors.accent, width: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (wide) {
              return Column(
                children: [
                  top,
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: hero)),
                        SizedBox(width: 360, child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: actions))),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                top,
                Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0), child: hero)),
                Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md), child: actions),
              ],
            );
          },
        ),
      ),
    );
  }
}
