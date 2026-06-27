import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../data/models/github_repo.dart';
import '../../../data/models/trending_topic.dart';
import '../../../services/providers.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(trendingTopicsProvider);
    final repos = ref.watch(trendingReposProvider);
    final funding = ref.watch(fundingEventsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brandPrimary,
          onRefresh: () async {
            ref.invalidate(trendingTopicsProvider);
            ref.invalidate(trendingReposProvider);
            ref.invalidate(fundingEventsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const _Header(),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: 'Trending Topics',
                subtitle: 'What the ecosystem is talking about',
              ),
              const SizedBox(height: AppSpacing.md),
              topics.when(
                loading: () => const _TopicsShimmer(),
                error: (e, _) => const _ErrorRow(),
                data: (list) => SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, i) => _TopicCard(topic: list[i]),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _SectionHeader(
                title: 'Trending Repositories',
                subtitle: 'Stars per week',
              ),
              const SizedBox(height: AppSpacing.md),
              repos.when(
                loading: () => const _RepoListShimmer(),
                error: (e, _) => const _ErrorRow(),
                data: (list) => Column(
                  children: list
                      .map((r) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                            child: _TrendingRepoTile(repo: r),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(
                title: 'Funding & Acquisitions',
                subtitle: 'Where the money is flowing',
              ),
              const SizedBox(height: AppSpacing.md),
              funding.when(
                loading: () => const _RepoListShimmer(),
                error: (e, _) => const _ErrorRow(),
                data: (list) => Column(
                  children: list
                      .map((f) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                            child: _FundingTile(event: f),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discover',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 2),
          Text(
            'Trends, repos, and money — at a glance.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TrendingTopic topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.topicColor(topic.name);
    return PressScale(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () {},
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 11, color: color),
                  const SizedBox(width: 3),
                  Text(
                    '+${topic.growthPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(topic.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(topic.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.sm),
            Text('${topic.articleCount} articles',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TrendingRepoTile extends StatelessWidget {
  final GithubRepo repo;
  const _TrendingRepoTile({required this.repo});

  Future<void> _open() async {
    final uri = Uri.parse(repo.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PressScale(
      onTap: _open,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.code_rounded,
                  color: AppColors.brandAccent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(repo.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '+${Format.compactNumber(repo.starsThisWeek)}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: AppColors.brandHighlight),
                    const SizedBox(width: 2),
                    Text(Format.compactNumber(repo.stars),
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingTile extends StatelessWidget {
  final FundingEvent event;
  const _FundingTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppColors.success),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.companyName,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                        '${event.round} · ${Format.relativeTime(event.announcedAt)}',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                Format.money(event.amountUsd),
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (event.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(event.description!,
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (event.investors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: event.investors
                  .map((inv) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceAlt
                              : AppColors.lightSurfaceAlt,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          inv,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicsShimmer extends StatelessWidget {
  const _TopicsShimmer();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) =>
            const LoadingShimmer(width: 200, height: 140, radius: AppSpacing.radiusLg),
      ),
    );
  }
}

class _RepoListShimmer extends StatelessWidget {
  const _RepoListShimmer();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child:
              LoadingShimmer(height: 84, radius: AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text('Couldn\'t load. Pull to refresh.',
          style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
