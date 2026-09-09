import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../services/providers.dart';
import '../../feed/presentation/widgets/feed_card.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(savedIdsProvider); // rebuild when a save toggles
    final saved = ref.watch(savedArticlesProvider);
    return Scaffold(
      body: saved.when(
        loading: () => const Column(children: [_Header(count: 0), StoryRowSkeleton(), StoryRowSkeleton()]),
        error: (_, _) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Header(count: 0), EmptyState(title: 'Could not load saved stories', body: 'Try again in a moment.')]),
        data: (items) => items.isEmpty
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _Header(count: 0), EmptyState(
                icon: AppIcons.bookmark,
                hue: AppColors.pink,
                figure: Figure.sittingReading,
                title: 'No stories saved yet.',
                body: 'Tap the bookmark on any story. Saved stories stay available offline.',
                actionLabel: 'Back to the feed',
                onAction: () => context.go(AppRoutes.feed),
              )])
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                itemCount: items.length + 1,
                separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const GutterDivider(),
                itemBuilder: (_, i) => i == 0 ? _Header(count: items.length) : StoryRow(items[i - 1]),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved', style: t.headlineLarge),
            const SizedBox(height: 3),
            Text(count == 1 ? '1 story, available offline' : '$count stories, available offline', style: AppTypography.kicker()),
          ],
        ),
      ),
    );
  }
}
