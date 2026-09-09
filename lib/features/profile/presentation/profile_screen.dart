import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final saved = ref.watch(savedIdsProvider);
    final t = Theme.of(context).textTheme;
    final isGuest = user == null || user.id == 'guest';
    final pro = ref.watch(proProvider);
    final interests = user?.interests ?? const <String>[];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      child: user?.photoUrl != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), child: Image.network(user!.photoUrl!, fit: BoxFit.cover, width: 48, height: 48))
                          : Text((user?.displayName.isNotEmpty ?? false) ? user!.displayName[0].toUpperCase() : 'G', style: t.headlineSmall),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isGuest ? 'Reading as guest' : user.displayName, style: t.headlineSmall),
                          const SizedBox(height: 2),
                          Text(isGuest ? 'Saved stories stay on this device' : user.email, style: t.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => context.push(AppRoutes.settings), icon: const Icon(AppIcons.filter)),
                  ],
                ),
              ),
            ),
          ),
          if (isGuest)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
                child: OutlinedButton(onPressed: () => context.push(AppRoutes.signIn), child: const Text('Sign in to sync across devices')),
              ),
            ),
          SliverToBoxAdapter(
            child: SectionHeader('Following', kicker: '${interests.length} topics lead your feed', action: 'Edit', onAction: () => _editInterests(context, ref, interests)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: interests.isEmpty
                  ? Text('Nothing yet. Tap Edit to pick what leads your feed.', style: t.bodyMedium)
                  : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final i in interests) TopicChip(label: i, selected: true, dense: true)]),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader('Library')),
          SliverList.list(children: [
            _Row(icon: AppIcons.bolt, title: pro.isPro ? 'TechiNews Pro' : 'Upgrade to Pro', trailing: pro.isPro ? 'Active' : 'Alerts', onTap: () => context.push(AppRoutes.pro)),
            const GutterDivider(),
            _Row(icon: AppIcons.bookmark, title: 'Saved stories', trailing: pro.isPro ? '${saved.length}' : '${saved.length} / ${ProNotifier.freeSaveLimit}', onTap: () => context.go(AppRoutes.saved)),
            const GutterDivider(),
            _Row(icon: AppIcons.bell, title: 'Notifications', trailing: _modeLabel(user?.notificationMode ?? NotificationMode.dailyDigest), onTap: () => context.push(AppRoutes.settings)),
            const GutterDivider(),
            _Row(icon: AppIcons.info, title: 'About', trailing: 'v${AppConstants.appVersion}', onTap: () => context.push(AppRoutes.settings)),
            const GutterDivider(),
          ]),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.xxl),
              child: TextButton(
                onPressed: () async {
                  await ref.read(currentUserProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.onboarding);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted, alignment: Alignment.centerLeft),
                child: Text(isGuest ? 'Reset this device' : 'Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _modeLabel(NotificationMode m) => switch (m) {
        NotificationMode.instant => 'Instant',
        NotificationMode.dailyDigest => 'Daily',
        NotificationMode.weeklyDigest => 'Weekly',
        NotificationMode.silent => 'Off',
      };

  Future<void> _editInterests(BuildContext context, WidgetRef ref, List<String> current) async {
    final picked = {...current};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What leads your feed', style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final i in Interests.all)
                      TopicChip(label: i, selected: picked.contains(i), onTap: () => setSheet(() => picked.contains(i) ? picked.remove(i) : picked.add(i))),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: () => Navigator.pop(ctx, picked), child: Text('Save ${picked.length} topics')),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      await ref.read(currentUserProvider.notifier).setInterests(result.toList());
      ref.invalidate(feedStateProvider);
    }
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.inkSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) Text(trailing!, style: AppTypography.kicker()),
            const SizedBox(width: 6),
            const Icon(AppIcons.chevronRight, size: 18, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
