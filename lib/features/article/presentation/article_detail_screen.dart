import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/topic_chip.dart';
import '../../../data/models/article.dart';
import '../../../services/providers.dart';
import 'widgets/discussion_card.dart';
import 'widgets/repo_card.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState
    extends ConsumerState<ArticleDetailScreen> {
  bool? _localSaved;

  @override
  Widget build(BuildContext context) {
    final asyncArticle = ref.watch(articleProvider(widget.articleId));

    return Scaffold(
      body: asyncArticle.when(
        loading: () => const _LoadingState(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (a) {
          if (a == null) {
            return const Center(child: Text('Article not found'));
          }
          final saved = _localSaved ?? a.isSaved;
          return _Body(
            article: a,
            saved: saved,
            onToggleSave: () async {
              setState(() => _localSaved = !saved);
              await ref
                  .read(articleRepositoryProvider)
                  .toggleSave(a.id);
            },
            onShare: () => Share.share(
              '${a.title}\n\n${a.url}',
              subject: a.title,
            ),
            onOpenSource: () async {
              final uri = Uri.parse(a.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Article article;
  final bool saved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback onOpenSource;

  const _Body({
    required this.article,
    required this.saved,
    required this.onToggleSave,
    required this.onShare,
    required this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          stretch: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: PressScale(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: PressScale(
                onTap: onShare,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.ios_share_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: PressScale(
                onTap: onToggleSave,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: saved ? AppColors.brandHighlight : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: article.imageUrl == null
                ? Container(
                    decoration:
                        const BoxDecoration(gradient: AppColors.brandGradient),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                          imageUrl: article.imageUrl!, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.4, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        article.source.name,
                        style: const TextStyle(
                            color: AppColors.brandPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(Format.relativeTime(article.publishedAt),
                        style: theme.textTheme.labelSmall),
                    if (article.author != null) ...[
                      Text(' · ', style: theme.textTheme.labelSmall),
                      Flexible(
                        child: Text(
                          article.author!,
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(article.title,
                    style: theme.textTheme.displaySmall?.copyWith(height: 1.2)),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in article.topics)
                      TopicChip(label: t, small: true),
                    for (final c in article.companies)
                      TopicChip(label: c, small: true),
                  ],
                ),
                if (article.summary != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(label: 'AI SUMMARY', icon: Icons.auto_awesome_rounded),
                  const SizedBox(height: AppSpacing.sm),
                  Text(article.summary!,
                      style: theme.textTheme.bodyLarge),
                ],
                if (article.whyItMatters != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(
                      label: 'WHY IT MATTERS',
                      icon: Icons.lightbulb_outline_rounded),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color:
                            AppColors.brandPrimary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      article.whyItMatters!,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],
                if (article.keyPoints.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(label: 'KEY POINTS', icon: Icons.list_alt_rounded),
                  const SizedBox(height: AppSpacing.md),
                  for (final point in article.keyPoints)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.brandAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (article.relatedRepos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(
                      label: 'RELATED REPOSITORIES',
                      icon: Icons.code_rounded),
                  const SizedBox(height: AppSpacing.md),
                  for (final r in article.relatedRepos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RepoCard(repo: r),
                    ),
                ],
                if (article.discussions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(
                      label: 'COMMUNITY DISCUSSIONS',
                      icon: Icons.forum_outlined),
                  const SizedBox(height: AppSpacing.md),
                  for (final d in article.discussions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DiscussionCard(post: d),
                    ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                FilledButton.icon(
                  onPressed: onOpenSource,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Read full article'),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.brandPrimary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.brandPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoadingShimmer(height: 220, radius: AppSpacing.radiusLg),
            const SizedBox(height: AppSpacing.lg),
            const LoadingShimmer(height: 28),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 28, width: 280),
            const SizedBox(height: AppSpacing.xl),
            const LoadingShimmer(height: 16),
            const SizedBox(height: 6),
            const LoadingShimmer(height: 16),
          ],
        ),
      ),
    );
  }
}
