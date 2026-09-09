import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/doodles.dart';
import '../../../data/models/article.dart';
import '../../../services/providers.dart';
import '../../article/presentation/widgets/repo_card.dart';
import 'widgets/feed_card.dart';

/// Client-side lenses over the ranked feed. The server already ranks; tabs
/// only narrow what is shown.
enum _Lens { top, trending, openSource, research, companies }

const _lensLabels = ['Top stories', 'Trending', 'Open source', 'Research', 'Companies'];

final _lensProvider = StateProvider<_Lens>((_) => _Lens.top);

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedStateProvider);
    final meta = ref.watch(feedMetaProvider).valueOrNull;
    final lens = ref.watch(_lensProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceRaised,
        onRefresh: () async {
          ref.invalidate(feedMetaProvider);
          await ref.read(feedStateProvider.notifier).refresh();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
              ref.read(feedStateProvider.notifier).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Masthead()),
              SliverToBoxAdapter(
                child: TabStrip(
                  labels: _lensLabels,
                  index: lens.index,
                  onChanged: (i) => ref.read(_lensProvider.notifier).state = _Lens.values[i],
                ),
              ),
              feed.when(
                loading: () => SliverList.list(children: const [
                  StoryRowSkeleton(withImage: true),
                  StoryRowSkeleton(),
                  StoryRowSkeleton(),
                  StoryRowSkeleton(),
                ]),
                error: (e, _) => SliverToBoxAdapter(
                  child: EmptyState(
                    icon: AppIcons.offline,
                    figure: Figure.clumsy,
                    hue: AppColors.pink,
                    title: 'The feed did not load',
                    body: 'We could not reach the server. Check your connection and pull down to try again.',
                    actionLabel: 'Retry',
                    onAction: () => ref.read(feedStateProvider.notifier).refresh(),
                  ),
                ),
                data: (state) => state.items.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyState(
                          figure: Figure.meditating,
                          hue: AppColors.purple,
                          title: 'Nothing here yet',
                          body: 'The first collection run has not landed. It runs every hour, so check back shortly.',
                          actionLabel: 'Adjust interests',
                          onAction: () => context.go(AppRoutes.profile),
                        ),
                      )
                    : _FeedList(state: state, meta: meta, lens: lens),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wordmark, a handwritten motto, the bell; then the search field.
class _Masthead extends ConsumerWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsListProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
        child: Column(
          children: [
            Row(
              children: [
                const Wordmark(size: 28),
                const Spacer(),
                Transform.rotate(
                  angle: -0.08,
                  child: Text('stay curious\nstay ahead', textAlign: TextAlign.center, style: AppTypography.hand(12, color: AppColors.accent)),
                ),
                const SizedBox(width: 6),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Inbox',
                      onPressed: () => context.push(AppRoutes.notifications),
                      icon: const Icon(AppIcons.bell, size: 24),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(color: AppColors.pink, shape: BoxShape.circle, border: Border.all(color: AppColors.canvas, width: 1.5)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: SearchBarButton(onTap: () => context.push(AppRoutes.search)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  final FeedState state;
  final FeedMeta? meta;
  final _Lens lens;
  const _FeedList({required this.state, required this.meta, required this.lens});

  List<Article> _apply(List<Article> items) {
    switch (lens) {
      case _Lens.top:
        return items;
      case _Lens.trending:
        return [...items]..sort((a, b) => b.trendScore.compareTo(a.trendScore));
      case _Lens.openSource:
        return items.where((a) => a.relatedRepos.isNotEmpty || a.source.type == ArticleSourceType.github).toList();
      case _Lens.research:
        final ids = {'arxiv', 'huggingface', 'hf_papers', 'hf'};
        return items.where((a) => ids.contains(a.source.id) || a.topics.any((t) => t.toLowerCase().contains('research'))).toList();
      case _Lens.companies:
        return items.where((a) => a.companies.isNotEmpty).toList();
    }
  }

  List<String> _topics(List<Article> items) {
    final counts = <String, int>{};
    for (final a in items.take(60)) {
      for (final t in a.topics) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _apply(state.items);
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(figure: Figure.float, hue: AppColors.cyan, title: 'Nothing in this lens yet', body: 'Try another tab, or pull down to refresh.'),
      );
    }
    final last = meta?.lastRun;
    final updated = last == null ? 'Updating' : 'Updated ${Format.relativeTime(last)}';
    final today = 'Today, ${DateFormat('d MMM').format(DateTime.now())}';

    final hot = items.take(5).toList();
    final hotIds = hot.map((a) => a.id).toSet();
    final repos = lens == _Lens.openSource ? const <Article>[] : items.where((a) => a.relatedRepos.isNotEmpty && !hotIds.contains(a.id)).take(3).toList();
    final repoIds = repos.map((a) => a.id).toSet();
    final rest = items.where((a) => !hotIds.contains(a.id) && !repoIds.contains(a.id)).toList();
    final topics = lens == _Lens.top ? _topics(state.items) : const <String>[];

    final breaking = lens == _Lens.top ? items.where(isBreaking).take(1).toList() : const <Article>[];
    final breakingIds = breaking.map((a) => a.id).toSet();
    final hotList = hot.where((a) => !breakingIds.contains(a.id)).toList();

    return SliverList.list(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(AppIcons.flame, size: 24, color: AppColors.ember),
            const SizedBox(width: 6),
            Scribble(
              thickness: 3,
              inset: -4,
              child: Text(lens == _Lens.top ? 'Hot now' : _lensLabels[lens.index], style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(width: 10),
            const LiveDot(),
            const SizedBox(width: 5),
            Expanded(child: Text(updated, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.kicker())),
            Text(today, style: AppTypography.kicker()),
          ],
        ),
      ),
      for (final a in breaking) BreakingCard(a),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        height: 318,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          itemCount: hotList.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, i) => TrendingCard(hotList[i], rank: i + 1),
        ),
      ),
      if (topics.isNotEmpty) ...[
        SectionHeader('Topics', icon: AppIcons.hashtag, iconColor: AppColors.purple, underline: AppColors.pink, action: 'See all', onAction: () => context.go(AppRoutes.discover)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in topics)
                HueTag('#${t.replaceAll(' ', '')}', hue: AppColors.hue(t), onTap: () => context.push('${AppRoutes.search}?q=${Uri.encodeComponent(t)}')),
            ],
          ),
        ),
      ],
      if (repos.isNotEmpty) ...[
        SectionHeader('From GitHub', icon: AppIcons.github, iconColor: AppColors.ink, underline: AppColors.green, action: 'See all', onAction: () => context.go(AppRoutes.discover)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Column(
            children: [
              for (final a in repos) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: RepoCard(a.relatedRepos.first, story: a)),
            ],
          ),
        ),
      ],
      if (rest.isNotEmpty) ...[
        const SectionHeader('Latest', kicker: 'Ranked over the last 10 days', underline: AppColors.accent),
        for (var i = 0; i < rest.length; i++) ...[
          if ((rest[i].imageUrl == null || rest[i].imageUrl!.isEmpty) && i % 3 == 1) ...[
            TypeCard(rest[i]),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            StoryRow(rest[i]),
            const GutterDivider(),
          ],
        ],
      ],
      if (state.loadingMore) const StoryRowSkeleton(),
      if (!state.hasMore && items.length > 10)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const DoodleFigure(Figure.reading, hue: AppColors.green, height: 120),
              const SizedBox(height: AppSpacing.sm),
              Text('That is everything from the last 10 days', style: AppTypography.hand(15, color: AppColors.inkMuted)),
            ],
          ),
        ),
    ]);
  }
}
