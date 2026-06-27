import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/topic_chip.dart';
import '../../../data/models/user.dart';
import '../../../services/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  final Set<String> _selectedInterests = {};
  NotificationMode _notifMode = NotificationMode.dailyDigest;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final notifier = ref.read(currentUserProvider.notifier);
    await notifier.setInterests(_selectedInterests.toList());
    if (mounted) context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _page == 0 ||
        (_page == 1 && _selectedInterests.length >= 3) ||
        _page == 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _StepIndicator(active: _page >= 0),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StepIndicator(active: _page >= 1),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StepIndicator(active: _page >= 2),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  _InterestsPage(
                    selected: _selectedInterests,
                    onToggle: (label) => setState(() {
                      if (_selectedInterests.contains(label)) {
                        _selectedInterests.remove(label);
                      } else {
                        _selectedInterests.add(label);
                      }
                    }),
                  ),
                  _NotificationsPage(
                    mode: _notifMode,
                    onChange: (m) => setState(() => _notifMode = m),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FilledButton(
                onPressed: canContinue ? _next : null,
                child: Text(
                  _page == 2 ? 'Get Started' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final bool active;
  const _StepIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? AppColors.brandPrimary
            : Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Tech intelligence,\nnot scrolling.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'AI-curated stories from across the tech ecosystem. GitHub trends, AI launches, startup funding, and developer discussions — all in one feed.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _FeatureBullet(
            icon: Icons.psychology_outlined,
            text: 'AI summaries — 30-second understanding of any story',
          ),
          const SizedBox(height: AppSpacing.lg),
          _FeatureBullet(
            icon: Icons.hub_outlined,
            text: 'GitHub repos auto-matched to every news item',
          ),
          const SizedBox(height: AppSpacing.lg),
          _FeatureBullet(
            icon: Icons.notifications_active_outlined,
            text: 'Smart notifications — only what matters to you',
          ),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _InterestsPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _InterestsPage({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you care about?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick at least 3. We\'ll tune your feed to match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: Interests.all
                    .map((label) => TopicChip(
                          label: label,
                          selected: selected.contains(label),
                          onTap: () => onToggle(label),
                        ))
                    .toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              '${selected.length}/${Interests.all.length} selected',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  final NotificationMode mode;
  final ValueChanged<NotificationMode> onChange;

  const _NotificationsPage({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification frequency',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can change this later in settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _NotifOption(
            mode: NotificationMode.instant,
            current: mode,
            onChange: onChange,
            title: 'Instant',
            body: 'Ping me when something big drops.',
            icon: Icons.flash_on_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _NotifOption(
            mode: NotificationMode.dailyDigest,
            current: mode,
            onChange: onChange,
            title: 'Daily digest',
            body: 'Top 5 stories every morning.',
            icon: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          _NotifOption(
            mode: NotificationMode.weeklyDigest,
            current: mode,
            onChange: onChange,
            title: 'Weekly digest',
            body: 'A focused weekly recap.',
            icon: Icons.calendar_view_week_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _NotifOption(
            mode: NotificationMode.silent,
            current: mode,
            onChange: onChange,
            title: 'Silent',
            body: 'No notifications. I\'ll open the app myself.',
            icon: Icons.notifications_off_outlined,
          ),
        ],
      ),
    );
  }
}

class _NotifOption extends StatelessWidget {
  final NotificationMode mode;
  final NotificationMode current;
  final ValueChanged<NotificationMode> onChange;
  final String title;
  final String body;
  final IconData icon;

  const _NotifOption({
    required this.mode,
    required this.current,
    required this.onChange,
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selected = mode == current;
    return GestureDetector(
      onTap: () => onChange(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPrimary.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected
                ? AppColors.brandPrimary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandPrimary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(body,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Radio<NotificationMode>(
              value: mode,
              groupValue: current,
              onChanged: (m) => onChange(m!),
            ),
          ],
        ),
      ),
    );
  }
}
