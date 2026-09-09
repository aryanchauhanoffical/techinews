import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/doodles.dart';
import '../../../services/providers.dart';

/// One question before the first feed: what should lead it. A grid of
/// hue-outlined tiles; three picks unlock the button, more is fine.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _picked = {};
  bool _busy = false;

  static const _minimum = 3;

  Future<void> _finish() async {
    setState(() => _busy = true);
    await ref.read(currentUserProvider.notifier).setInterests(_picked.toList());
    if (mounted) context.go(AppRoutes.feed);
  }

  Future<void> _skip() async {
    setState(() => _busy = true);
    await ref.read(currentUserProvider.notifier).setInterests(const ['Artificial Intelligence', 'Open Source', 'Startups']);
    if (mounted) context.go(AppRoutes.feed);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final remaining = _minimum - _picked.length;
    final progress = (_picked.length / _minimum).clamp(0.0, 1.0);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth > 900 ? 4 : (box.maxWidth > 600 ? 3 : 2);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => context.go(AppRoutes.splash),
                        icon: const Icon(AppIcons.back),
                        style: IconButton.styleFrom(backgroundColor: AppColors.surfaceRaised),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Step 1 of 1', style: AppTypography.kicker()),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _minimum; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    width: 34,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: i < _picked.length ? AppColors.accent : AppColors.hairlineStrong,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _busy ? null : _skip, child: const Text('Skip')),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.lg),
                        sliver: SliverList.list(children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: 'Choose $_minimum topics\n',
                                        children: [
                                          WidgetSpan(
                                            child: Scribble(
                                              color: AppColors.pink,
                                              thickness: 4,
                                              inset: -6,
                                              child: Text('to start', style: AppTypography.serif(30, height: 1.1, spacing: -0.6, color: AppColors.accent)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: AppTypography.serif(30, height: 1.1, spacing: -0.6),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text('Create your personal feed. Everything else still appears, just lower.', style: t.bodyMedium),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: SizedBox(width: 84, child: StickyNote('Pick what\nexcites you!')),
                              ),
                            ],
                          ),
                        ]),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                        sliver: SliverGrid.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: Interests.all.length,
                          itemBuilder: (_, i) {
                            final name = Interests.all[i];
                            final on = _picked.contains(name);
                            return _Tile(
                              name: name,
                              selected: on,
                              onTap: () => setState(() => on ? _picked.remove(name) : _picked.add(name)),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.lg),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: remaining > 0 ? const [] : [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 22, spreadRadius: -4)],
                    ),
                    child: FilledButton(
                      onPressed: _busy || remaining > 0 ? null : _finish,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: Color.lerp(AppColors.surfaceRaised, AppColors.accent, progress * 0.5),
                        disabledForegroundColor: AppColors.inkSecondary,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(remaining > 0 ? 'Pick $remaining more' : 'Create my feed'),
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 260),
                            offset: Offset(remaining > 0 ? 0 : 0.2, 0),
                            child: DoodleArrow(color: remaining > 0 ? AppColors.inkSecondary : AppColors.onAccent, width: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _Tile({required this.name, required this.selected, required this.onTap});

  static const _icons = <String, IconData>{
    'Artificial Intelligence': AppIcons.ai,
    'Startups': AppIcons.startups,
    'Open Source': AppIcons.code,
    'Cybersecurity': AppIcons.security,
    'Web Development': AppIcons.web,
    'Mobile Development': AppIcons.mobile,
    'Space Tech': AppIcons.space,
    'Robotics': AppIcons.robotics,
    'Hardware': AppIcons.hardware,
    'Finance Tech': AppIcons.finance,
    'Blockchain': AppIcons.blockchain,
    'Apple': AppIcons.web,
    'Google': AppIcons.search,
    'NVIDIA': AppIcons.hardware,
    'OpenAI': AppIcons.openai,
    'Meta': AppIcons.people,
    'Microsoft': AppIcons.microsoft,
    'Hiring': AppIcons.hiring,
  };

  @override
  Widget build(BuildContext context) {
    final hue = AppColors.hue(name);
    final icon = _icons[name] ?? AppIcons.hashtag;
    final reduced = MediaQuery.of(context).disableAnimations;
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      child: AnimatedScale(
        duration: Duration(milliseconds: reduced ? 0 : 180),
        curve: Curves.easeOutBack,
        scale: selected ? 1.02 : 1,
        child: PopCard(
          hue: selected ? hue : hue.withValues(alpha: 0.45),
          borderWidth: selected ? 2 : 1.4,
          glow: selected,
          fill: Color.alphaBlend(hue.withValues(alpha: selected ? 0.16 : 0.06), AppColors.surface),
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Positioned(right: -10, bottom: -14, child: Icon(icon, size: 72, color: hue.withValues(alpha: selected ? 0.22 : 0.10))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 26, color: hue),
                      const Spacer(),
                      AnimatedContainer(
                        duration: Duration(milliseconds: reduced ? 0 : 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selected ? hue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: selected ? hue : AppColors.hairlineStrong, width: 1.6),
                        ),
                        child: selected ? Icon(AppIcons.check, size: 14, color: hue == AppColors.yellow || hue == AppColors.green ? AppColors.onYellow : AppColors.onAccent) : null,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.serif(15, weight: FontWeight.w700, height: 1.2, color: selected ? AppColors.ink : AppColors.inkSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
