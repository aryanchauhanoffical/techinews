import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/topic_chip.dart';
import '../../../../data/models/article.dart';
import '../../../../services/providers.dart';

class FeedCard extends ConsumerStatefulWidget {
  final Article article;
  const FeedCard({super.key, required this.article});

  @override
  ConsumerState<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<FeedCard> {
  late bool _isSaved = widget.article.isSaved;

  Future<void> _toggleSave() async {
    setState(() => _isSaved = !_isSaved);
    await ref
        .read(articleRepositoryProvider)
        .toggleSave(widget.article.id);
  }

  Future<void> _share() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.url}',
      subject: widget.article.title,
    );
  }

  void _openDetail() {
    context.push(AppRoutes.articlePath(widget.article.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.article;

    return PressScale(
      onTap: _openDetail,
      haptic: false,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(article: a),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SourceRow(article: a),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    a.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (a.summary != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      a.summary!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in a.topics.take(3))
                        TopicChip(label: t, small: true),
                      for (final c in a.companies.take(2))
                        TopicChip(label: c, small: true),
                    ],
                  ),
                  if (a.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 14, color: AppColors.brandPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'AI KEY POINTS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.brandPrimary,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final point in a.keyPoints.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 7),
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brandAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _ActionButton(
                        icon: _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        label: _isSaved ? 'Saved' : 'Save',
                        active: _isSaved,
                        onTap: _toggleSave,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        onTap: _share,
                      ),
                      const Spacer(),
                      _TrendBadge(score: a.trendScore),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final Article article;
  const _HeroImage({required this.article});

  @override
  Widget build(BuildContext context) {
    if (article.imageUrl == null) {
      return Container(
        height: 140,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: const Center(
          child: Icon(Icons.article_outlined, color: Colors.white, size: 36),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: article.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurfaceAlt
                  : AppColors.lightSurfaceAlt,
            ),
            errorWidget: (_, __, ___) => Container(
              decoration: const BoxDecoration(gradient: AppColors.brandGradient),
              child: const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.4, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final Article article;
  const _SourceRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            article.source.name,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          Format.relativeTime(article.publishedAt),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        if (article.author != null)
          Text(
            article.author!,
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? AppColors.brandPrimary
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.brandPrimary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: active
                ? AppColors.brandPrimary.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final int score;
  const _TrendBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final hot = score >= 85;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (hot ? AppColors.warning : AppColors.info)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: (hot ? AppColors.warning : AppColors.info)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hot ? Icons.local_fire_department_rounded : Icons.trending_up_rounded,
            color: hot ? AppColors.warning : AppColors.info,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              color: hot ? AppColors.warning : AppColors.info,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
