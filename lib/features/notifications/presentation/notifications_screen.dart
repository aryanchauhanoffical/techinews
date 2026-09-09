import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/models/user.dart';
import '../../../services/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _label(NotificationKind k) => switch (k) {
        NotificationKind.breaking => 'Breaking',
        NotificationKind.digest => 'Digest',
        NotificationKind.githubTrend => 'GitHub',
        NotificationKind.funding => 'Funding',
        NotificationKind.hiring => 'Hiring',
        NotificationKind.system => 'System',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsListProvider);
    final t = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final mode = user?.notificationMode ?? NotificationMode.dailyDigest;
    final modeLabel = switch (mode) {
      NotificationMode.instant => 'Instant alerts on',
      NotificationMode.dailyDigest => 'Daily digest at 8:00',
      NotificationMode.weeklyDigest => 'Weekly digest on Sunday',
      NotificationMode.silent => 'Notifications off',
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inbox', style: t.headlineLarge),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => context.push(AppRoutes.settings),
                            child: Text(modeLabel, style: AppTypography.kicker(color: AppColors.accent)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(notificationsRepositoryProvider).markAllRead();
                        ref.invalidate(notificationsListProvider);
                      },
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: GutterDivider()),
          list.when(
            loading: () => SliverList.list(children: const [StoryRowSkeleton(), StoryRowSkeleton()]),
            error: (_, _) => const SliverToBoxAdapter(child: EmptyState(title: 'Inbox unavailable', body: 'Could not load notifications.')),
            data: (items) => items.isEmpty
                ? SliverToBoxAdapter(
                    child: EmptyState(
                      icon: AppIcons.bell,
                      figure: Figure.coffee,
                      hue: AppColors.yellow,
                      title: 'Quiet so far',
                      body: 'Digests and alerts land here. Change how often in settings.',
                      actionLabel: 'Notification settings',
                      onAction: () => context.push(AppRoutes.settings),
                    ),
                  )
                : SliverList.list(children: [
                    for (final n in items) ...[
                      InkWell(
                        onTap: () async {
                          await ref.read(notificationsRepositoryProvider).markRead(n.id);
                          ref.invalidate(notificationsListProvider);
                          if (n.articleId != null && context.mounted) context.push(AppRoutes.articlePath(n.articleId!));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 14,
                                child: n.isRead
                                    ? null
                                    : Container(
                                        margin: const EdgeInsets.only(top: 5),
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                      ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(_label(n.kind), style: AppTypography.kicker(color: n.isRead ? AppColors.inkMuted : AppColors.accent)),
                                        const Spacer(),
                                        Text(FormatShort.short(n.receivedAt), style: AppTypography.kicker()),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(n.title, style: t.titleLarge?.copyWith(color: n.isRead ? AppColors.inkSecondary : AppColors.ink)),
                                    const SizedBox(height: 4),
                                    Text(n.body, style: t.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (n.imageUrl != null) ...[
                                const SizedBox(width: AppSpacing.md),
                                InkImage(n.imageUrl, width: 56, height: 56, radius: AppSpacing.radiusSm),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const GutterDivider(),
                    ],
                  ]),
          ),
        ],
      ),
    );
  }
}
