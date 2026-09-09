import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/doodles.dart';
import '../../../../core/widgets/ink_widgets.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../data/models/article.dart';
import '../../../../services/providers.dart';

/// Card system. Five variants, one visual language:
///  A [StoryHero]     large image + headline, full width
///  B [TypeCard]      typography-led, for stories without an image
///  C [StoryRow]      compact horizontal row
///  D [TrendingCard]  carousel "Trending #N" sticker card
///  E [BreakingCard]  pink-outlined breaking story
/// All share [SourceLine], [_Stats] and [_Save].

String sourceName(Article a) {
  final n = a.source.name;
  return n.length > 22 ? '${n.substring(0, 21)}…' : n;
}

/// First topic, used as the category badge.
String? category(Article a) => a.topics.isEmpty ? null : a.topics.first;

/// A story is "breaking" when it scored very high and is under six hours old.
bool isBreaking(Article a) => a.trendScore >= 90 && DateTime.now().difference(a.publishedAt).inHours < 6;

IconData categoryIcon(String? c) {
  switch ((c ?? '').toLowerCase()) {
    case 'ai':
    case 'artificial intelligence':
      return AppIcons.sparkle;
    case 'open source':
      return AppIcons.code;
    case 'startups':
    case 'funding':
      return AppIcons.startups;
    case 'cybersecurity':
    case 'security':
      return AppIcons.security;
    case 'hardware':
      return AppIcons.hardware;
    case 'space tech':
    case 'space':
      return AppIcons.space;
    case 'web development':
      return AppIcons.globe;
    case 'mobile development':
      return AppIcons.mobile;
    case 'research':
      return AppIcons.research;
    default:
      return AppIcons.news;
  }
}

/// Source avatar, name, time.
class SourceLine extends StatelessWidget {
  final Article article;
  const SourceLine(this.article, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = article;
    return Row(
      children: [
        SourceAvatar(a.source.name, iconUrl: a.source.iconUrl, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(sourceName(a), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.sans(13, weight: FontWeight.w600, height: 1, color: AppColors.inkSecondary)),
        ),
        const SizedBox(width: 8),
        Text(FormatShort.short(a.publishedAt), style: AppTypography.mono(12.5, color: AppColors.inkMuted)),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final Article a;
  const _Stats(this.a);
  @override
  Widget build(BuildContext context) {
    final hot = a.trendScore >= 80;
    return Row(
      children: [
        Icon(hot ? AppIcons.flame : AppIcons.trending, size: 15, color: hot ? AppColors.ember : AppColors.inkMuted),
        const SizedBox(width: 3),
        Text('${a.trendScore}', style: AppTypography.mono(12.5, weight: FontWeight.w600, color: hot ? AppColors.ember : AppColors.inkMuted)),
        if (a.coverage > 1) ...[
          const SizedBox(width: 12),
          const Icon(AppIcons.sources, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 3),
          Text('${a.coverage}', style: AppTypography.mono(12.5, color: AppColors.inkMuted)),
        ],
        if (a.discussions.isNotEmpty) ...[
          const SizedBox(width: 12),
          const Icon(AppIcons.comments, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 3),
          Text('${a.discussions.length}', style: AppTypography.mono(12.5, color: AppColors.inkMuted)),
        ],
      ],
    );
  }
}

class _Save extends ConsumerWidget {
  final Article a;
  const _Save(this.a);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedIdsProvider).contains(a.id);
    return PopBookmark(
      saved: saved,
      onTap: () async {
        final ok = await ref.read(savedIdsProvider.notifier).toggle(a.id);
        if (!ok && context.mounted) context.push(AppRoutes.pro);
      },
    );
  }
}

/// Blue disc with a doodle arrow. The "open" affordance on poster cards.
class _Go extends StatelessWidget {
  const _Go();
  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
        child: const DoodleArrow(color: AppColors.onAccent, width: 16),
      );
}

void _open(BuildContext context, Article a) => context.push(AppRoutes.articlePath(a.id));

/// D. Carousel card: hue outline by rank, image with a "Trending #N"
/// sticker, source, headline, stats, save, go.
class TrendingCard extends StatelessWidget {
  final Article article;
  final int rank;
  final double width;
  const TrendingCard(this.article, {super.key, required this.rank, this.width = 300});

  @override
  Widget build(BuildContext context) {
    final a = article;
    final t = Theme.of(context).textTheme;
    final hue = [AppColors.yellow, AppColors.pink, AppColors.green, AppColors.purple, AppColors.cyan][(rank - 1) % 5];
    return SizedBox(
      width: width,
      child: PressScale(
        onTap: () => _open(context, a),
        child: PopCard(
          hue: hue,
          glow: rank == 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  InkImage(a.imageUrl, width: width, height: 168, radius: 0, label: a.source.name, category: category(a)),
                  Positioned(left: 12, top: 12, child: Sticker('Trending #$rank', color: hue, icon: rank == 1 ? AppIcons.flame : null)),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SourceLine(a),
                      const SizedBox(height: 8),
                      Text(a.title, style: t.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(children: [Expanded(child: _Stats(a)), _Save(a), const SizedBox(width: 4), const _Go()]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A. Full-width image card. Category sticker on the image.
class StoryHero extends StatelessWidget {
  final Article article;
  const StoryHero(this.article, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = article;
    final t = Theme.of(context).textTheme;
    final cat = category(a);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: PressScale(
        onTap: () => _open(context, a),
        child: PopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(aspectRatio: 16 / 9, child: InkImage(a.imageUrl, width: double.infinity, radius: 0, label: a.source.name, category: category(a))),
                  if (cat != null) Positioned(left: 12, top: 12, child: Sticker(cat, color: AppColors.hue(cat))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourceLine(a),
                    const SizedBox(height: 8),
                    Text(a.title, style: t.headlineMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (a.summary != null && a.summary!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(a.summary!, style: t.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [Expanded(child: _Stats(a)), _Save(a), const SizedBox(width: 4), const _Go()]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// B. Typography-led card for stories without an image: big headline on a
/// hue-tinted surface with an oversized category glyph and a spark.
class TypeCard extends StatelessWidget {
  final Article article;
  const TypeCard(this.article, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = article;
    final t = Theme.of(context).textTheme;
    final cat = category(a);
    final hue = AppColors.hue(cat ?? a.source.name);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: PressScale(
        onTap: () => _open(context, a),
        child: PopCard(
          hue: hue,
          fill: Color.alphaBlend(hue.withValues(alpha: 0.08), AppColors.surface),
          child: Stack(
            children: [
              Positioned(right: -18, bottom: -22, child: Icon(categoryIcon(cat), size: 140, color: hue.withValues(alpha: 0.12))),
              Positioned(right: 14, top: 12, child: Spark(size: 16, color: hue)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cat != null) Sticker(cat, color: hue, tilt: 0),
                    const SizedBox(height: 12),
                    Text(a.title, style: t.headlineLarge, maxLines: 4, overflow: TextOverflow.ellipsis),
                    if (a.summary != null && a.summary!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(a.summary!, style: t.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 12),
                    SourceLine(a),
                    const SizedBox(height: 4),
                    Row(children: [Expanded(child: _Stats(a)), _Save(a), const SizedBox(width: 4), const _Go()]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// C. Compact row: source, headline, stats left; thumbnail right.
class StoryRow extends StatelessWidget {
  final Article article;
  final bool showThumb;
  const StoryRow(this.article, {super.key, this.showThumb = true});

  @override
  Widget build(BuildContext context) {
    final a = article;
    final t = Theme.of(context).textTheme;
    final read = a.isRead;
    final cat = category(a);
    return InkWell(
      onTap: () => _open(context, a),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (cat != null) ...[HueTag(cat, dense: true), const SizedBox(width: 8)],
                      Flexible(child: SourceLine(a)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.title,
                    style: t.headlineSmall?.copyWith(color: read ? AppColors.inkSecondary : AppColors.ink),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [Expanded(child: _Stats(a)), _Save(a)]),
                ],
              ),
            ),
            if (showThumb) ...[
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InkImage(a.imageUrl, width: 96, height: 96, radius: AppSpacing.radiusMd, label: a.source.name, category: category(a)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// E. Breaking story: pink outline and glow, "Breaking" sticker, headline
/// first. Shown above the carousel when a very high score is under 6h old.
class BreakingCard extends StatelessWidget {
  final Article article;
  const BreakingCard(this.article, {super.key});

  @override
  Widget build(BuildContext context) {
    final a = article;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
      child: PressScale(
        onTap: () => _open(context, a),
        child: PopCard(
          hue: AppColors.pink,
          glow: true,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Sticker('Breaking', color: AppColors.pink, icon: AppIcons.bolt, tilt: 0),
                  const SizedBox(width: 10),
                  Expanded(child: SourceLine(a)),
                ],
              ),
              const SizedBox(height: 10),
              Text(a.title, style: t.headlineMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [Expanded(child: _Stats(a)), _Save(a), const SizedBox(width: 4), const _Go()]),
            ],
          ),
        ),
      ),
    );
  }
}
