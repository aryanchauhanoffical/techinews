import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/topic_chip.dart';
import '../../../data/models/user.dart';
import '../../../services/pro.dart';
import '../../../services/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _repo = 'https://github.com/aryanchauhanoffical/techinews';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final mode = user?.notificationMode ?? NotificationMode.dailyDigest;
    final isPro = ref.watch(isProProvider);
    final t = Theme.of(context).textTheme;

    Widget option(NotificationMode m, String title, String body, {bool pro = false}) {
      final on = m == mode;
      final locked = pro && !isPro;
      return InkWell(
        onTap: () => locked ? context.push(AppRoutes.pro) : ref.read(currentUserProvider.notifier).setNotificationMode(m),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(title, style: t.titleMedium),
                      if (pro) ...[const SizedBox(width: 8), Text(locked ? 'PRO' : 'PRO ✓', style: AppTypography.kicker(color: AppColors.accent))],
                    ]),
                    const SizedBox(height: 2),
                    Text(body, style: t.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: on ? AppColors.accent : AppColors.hairlineStrong, width: on ? 6 : 1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const SectionHeader('Notifications', kicker: 'One choice. We keep to it.'),
          option(NotificationMode.instant, 'Instant', 'A push the moment a story scores 85 or higher.', pro: true),
          const GutterDivider(),
          option(NotificationMode.dailyDigest, 'Daily digest', 'The top stories, once a day at 8:00 local time.'),
          const GutterDivider(),
          option(NotificationMode.weeklyDigest, 'Weekly digest', 'Sunday morning. The week in ten stories.'),
          const GutterDivider(),
          option(NotificationMode.silent, 'Off', 'No pushes. The inbox still fills.'),
          const GutterDivider(),
          SectionHeader('Topic alerts', kicker: isPro ? 'A push only for these' : 'Pro. A push only for what you name.'),
          _TopicAlerts(isPro: isPro),
          const SectionHeader('How the feed is built'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fact('Sources', 'Forty feeds: lab blogs, tech press, newsletters, subreddits, GitHub releases, Hacker News, arXiv, Hugging Face.'),
                _fact('Cadence', 'A collector runs every hour, ranks what changed, and summarises the top thirty.'),
                _fact('Ranking', 'Source weight, engagement, and recency. No source gets more than four of the top slots.'),
              ],
            ),
          ),
          const SectionHeader('About'),
          _link(context, 'Source code', _repo),
          const GutterDivider(),
          _link(context, 'Privacy', '$_repo/blob/main/PRIVACY.md'),
          const GutterDivider(),
          _link(context, 'Terms', '$_repo/blob/main/TERMS.md'),
          const GutterDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
            child: Text('${AppConstants.appName}  ·  v${AppConstants.appVersion}', style: AppTypography.kicker()),
          ),
        ],
      ),
    );
  }

  Widget _fact(String k, String v) => Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 84, child: Text(k, style: AppTypography.kicker(color: AppColors.accent))),
              Expanded(child: Text(v, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
      );

  Widget _link(BuildContext context, String title, String url) => InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              const Icon(AppIcons.external, size: 16, color: AppColors.inkMuted),
            ],
          ),
        ),
      );
}


class _TopicAlerts extends ConsumerStatefulWidget {
  final bool isPro;
  const _TopicAlerts({required this.isPro});
  @override
  ConsumerState<_TopicAlerts> createState() => _TopicAlertsState();
}

class _TopicAlertsState extends ConsumerState<_TopicAlerts> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terms = ref.watch(topicAlertsProvider);
    final t = Theme.of(context).textTheme;
    if (!widget.isPro) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: OutlinedButton(onPressed: () => context.push(AppRoutes.pro), child: const Text('Unlock topic alerts')),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) {
              ref.read(topicAlertsProvider.notifier).add(v);
              _c.clear();
            },
            decoration: const InputDecoration(hintText: 'Company, repo, or keyword. Press return.'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (terms.isEmpty)
            Text('Nothing yet. Try "Anthropic", "llama.cpp", or "Rust".', style: t.bodySmall)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final x in terms) TopicChip(label: '$x  ×', selected: true, dense: true, onTap: () => ref.read(topicAlertsProvider.notifier).remove(x))],
            ),
        ],
      ),
    );
  }
}
