import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../data/models/notification_item.dart';
import '../../../services/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsListProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Text('Notifications',
                      style: Theme.of(context).textTheme.displaySmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markAllRead();
                      ref.invalidate(notificationsListProvider);
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifs.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brandPrimary)),
                error: (e, _) => Center(child: Text('$e')),
                data: (list) {
                  if (list.isEmpty) return const _EmptyNotifs();
                  return RefreshIndicator(
                    color: AppColors.brandPrimary,
                    onRefresh: () async =>
                        ref.invalidate(notificationsListProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => _NotificationTile(item: list[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  Color _kindColor() {
    switch (item.kind) {
      case NotificationKind.breaking:
        return AppColors.danger;
      case NotificationKind.funding:
        return AppColors.success;
      case NotificationKind.githubTrend:
        return AppColors.brandAccent;
      case NotificationKind.hiring:
        return AppColors.info;
      case NotificationKind.digest:
        return AppColors.brandPrimary;
      case NotificationKind.system:
        return AppColors.darkTextMuted;
    }
  }

  IconData _kindIcon() {
    switch (item.kind) {
      case NotificationKind.breaking:
        return Icons.flash_on_rounded;
      case NotificationKind.funding:
        return Icons.attach_money_rounded;
      case NotificationKind.githubTrend:
        return Icons.trending_up_rounded;
      case NotificationKind.hiring:
        return Icons.work_outline_rounded;
      case NotificationKind.digest:
        return Icons.wb_sunny_outlined;
      case NotificationKind.system:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _kindColor();
    return PressScale(
      onTap: () async {
        await ref.read(notificationsRepositoryProvider).markRead(item.id);
        ref.invalidate(notificationsListProvider);
        if (item.articleId != null && context.mounted) {
          context.push(AppRoutes.articlePath(item.articleId!));
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: item.isRead
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: item.isRead
                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_kindIcon(), color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.body,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(Format.relativeTime(item.receivedAt),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifs extends StatelessWidget {
  const _EmptyNotifs();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 40, color: AppColors.brandPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('All caught up',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('We\'ll ping you when something worth your time drops.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
