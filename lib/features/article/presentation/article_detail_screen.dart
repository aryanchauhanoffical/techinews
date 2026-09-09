import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/doodles.dart';
import '../../feed/presentation/widgets/feed_card.dart';
import '../../../data/models/article.dart';
import '../../../services/pro.dart';
import '../../../services/providers.dart';
import 'widgets/discussion_card.dart';
import 'widgets/repo_card.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});
  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(articleRepositoryProvider).markRead(widget.articleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final article = ref.watch(articleProvider(widget.articleId));
    return Scaffold(
      body: article.when(
        loading: () => const SafeArea(child: Column(children: [StoryRowSkeleton(withImage: true), StoryRowSkeleton()])),
        error: (e, _) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(),
              EmptyState(
                icon: AppIcons.offline,
                figure: Figure.clumsy,
                hue: AppColors.pink,
                title: 'Could not open this story',
                body: 'The server did not answer. Go back and try again in a moment.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(articleProvider(widget.articleId)),
              ),
            ],
          ),
        ),
        data: (a) => a == null
            ? SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const BackButton(), EmptyState(figure: Figure.levitate, hue: AppColors.purple, title: 'Story not found', body: 'It may have been removed from the feed.')]))
            : _Body(a),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Article a;
  const _Body(this.a);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final saved = ref.watch(savedIdsProvider).contains(a.id);
    final points = a.keyPoints;

    Future<void> toggleSave() async {
      final ok = await ref.read(savedIdsProvider.notifier).toggle(a.id);
      if (!ok && context.mounted) context.push(AppRoutes.pro);
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                backgroundColor: AppColors.canvas,
                leading: _Glyph(icon: AppIcons.back, onTap: () => context.pop(), over: true),
                actions: [
                  _Glyph(icon: AppIcons.share, onTap: () => Share.share('${a.title}\n${a.url}'), over: true),
                  _Glyph(
                    icon: saved ? AppIcons.bookmarkFilled : AppIcons.bookmark,
                    color: saved ? AppColors.accent : null,
                    onTap: toggleSave,
                    over: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            InkImage(a.imageUrl, radius: 0, label: a.source.name, quiet: true, category: category(a)),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0x66000000), Color(0x00000000), Color(0x990E1320)],
                                  stops: [0, 0.35, 1],
                                ),
                              ),
                            ),
                            if (category(a) != null)
                              Positioned(left: 16, bottom: 16, child: Sticker(category(a)!, color: AppColors.hue(category(a)!))),
                          ],
                        ),
                      ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
                sliver: SliverList.list(children: [
                  _SourceRow(a),
                  const SizedBox(height: AppSpacing.lg),
                  Text(a.title, style: t.displaySmall),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(AppIcons.clock, size: 14, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text('${_readMinutes(a)} min read', style: AppTypography.mono(12, color: AppColors.inkMuted)),
                      const SizedBox(width: 14),
                      ScoreMark(a.trendScore),
                      const SizedBox(width: 14),
                      if (a.coverage > 1) ...[
                        const Icon(AppIcons.sources, size: 14, color: AppColors.inkMuted),
                        const SizedBox(width: 4),
                        Text('${a.coverage} sources', style: AppTypography.mono(12, color: AppColors.inkMuted)),
                        const SizedBox(width: 14),
                      ],
                      if (a.author != null && a.author!.isNotEmpty)
                        Flexible(child: Text('By ${a.author}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.mono(12, color: AppColors.inkMuted))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (a.summary != null) Text(a.summary!, style: t.bodyLarge?.copyWith(color: AppColors.ink, fontSize: 17.5, height: 1.65)),
                  if (points.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Row(children: [Text('Key points', style: t.titleLarge), const SizedBox(width: 6), const Spark(size: 12)]),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < points.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 12, top: 1),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.accentWash, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                              child: Text('${i + 1}', style: AppTypography.sans(12, weight: FontWeight.w700, height: 1, color: AppColors.accent)),
                            ),
                            Expanded(child: Text(points[i], style: t.bodyLarge?.copyWith(color: AppColors.ink))),
                          ],
                        ),
                      ),
                  ],
                  if (a.whyItMatters != null && a.whyItMatters!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Why it matters', style: t.titleMedium?.copyWith(color: AppColors.accent)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(a.whyItMatters!, style: t.bodyLarge?.copyWith(color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ],
                  if (_paragraphs(a).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Text('From the story', style: t.titleLarge),
                    for (final para in _paragraphs(a)) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(para, style: t.bodyLarge?.copyWith(height: 1.7)),
                    ],
                  ],
                  if (a.topics.isNotEmpty || a.stack.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final x in [...a.topics, ...a.stack])
                          HueTag('#${x.replaceAll(' ', '')}', hue: AppColors.hue(x), dense: true, onTap: () => context.push('${AppRoutes.search}?q=${Uri.encodeComponent(x)}')),
                      ],
                    ),
                  ],
                  if (a.relatedRepos.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Text('The code', style: t.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    for (final r in a.relatedRepos) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: RepoCard(r)),
                  ],
                  if (a.discussions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('Discussion', style: t.titleLarge),
                    for (final d in a.discussions) ...[DiscussionCard(d), const Divider()],
                  ],
                ]),
              ),
              if (a.relatedIds.isNotEmpty) SliverToBoxAdapter(child: _Related(ids: a.relatedIds)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.canvas, border: Border(top: BorderSide(color: AppColors.hairline))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(a.url), mode: LaunchMode.externalApplication),
                icon: const Icon(AppIcons.external, size: 16),
                label: Text('Read at ${a.source.name}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Round app-bar action. Over an image it gets a dark disc so it stays
/// legible on any photo; over the canvas it is a plain icon.
class _Glyph extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool over;
  final Color? color;
  const _Glyph({required this.icon, required this.onTap, required this.over, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: over ? AppColors.canvas.withValues(alpha: 0.55) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 20, color: color ?? AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Source avatar, name, time, and a Follow toggle that adds the source to
/// topic alerts. Free readers see the paywall, which is where the feature
/// is explained.
class _SourceRow extends ConsumerWidget {
  final Article a;
  const _SourceRow(this.a);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(topicAlertsProvider);
    final isPro = ref.watch(isProProvider);
    final name = a.source.name;
    final following = alerts.any((x) => x.toLowerCase() == name.toLowerCase());
    return Row(
      children: [
        SourceAvatar(name, iconUrl: a.source.iconUrl, size: 40),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.sans(15, weight: FontWeight.w600, height: 1.2)),
              const SizedBox(height: 3),
              Text('${Format.relativeTime(a.publishedAt)}  ·  ${Format.absoluteDate(a.publishedAt)}', style: AppTypography.kicker()),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 34,
          child: following
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: () => ref.read(topicAlertsProvider.notifier).remove(name),
                  child: const Text('Following'),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () {
                    if (isPro) {
                      ref.read(topicAlertsProvider.notifier).add(name);
                    } else {
                      context.push(AppRoutes.pro);
                    }
                  },
                  child: const Text('Follow'),
                ),
        ),
      ],
    );
  }
}

int _readMinutes(Article a) {
  final words = [a.summary ?? '', a.body ?? '', ...a.keyPoints, a.whyItMatters ?? ''].join(' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return (words / 200).ceil().clamp(1, 30);
}

/// Body text as short paragraphs. Extracted text is uneven, so this keeps
/// only substantial prose lines, stops at trailing link lists, and skips
/// anything that repeats the summary.
List<String> _paragraphs(Article a) {
  final body = (a.body ?? '').trim();
  if (body.isEmpty) return const [];
  final stop = RegExp(r'^(recent articles|related|more on|posted|tags:|share this|subscribe|read more)', caseSensitive: false);
  final out = <String>[];
  for (final raw in body.split(RegExp(r'\n+'))) {
    final line = raw.trim();
    if (stop.hasMatch(line)) break;
    if (line.length < 80) continue;
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('|')) continue;
    if (a.summary != null && line == a.summary!.trim()) continue;
    out.add(line);
    if (out.length >= 8) break;
  }
  return out;
}

/// Related stories: the same story as carried by other sources, as a
/// horizontal strip of compact poster cards.
class _Related extends ConsumerWidget {
  final List<String> ids;
  const _Related({required this.ids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedArticlesProvider(ids));
    final t = Theme.of(context).textTheme;
    return related.maybeWhen(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Related stories', icon: AppIcons.sources, iconColor: AppColors.purple, underline: AppColors.purple),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      return SizedBox(
                        width: 240,
                        child: PressScale(
                          onTap: () => context.push(AppRoutes.articlePath(r.id)),
                          child: PopCard(
                            hue: AppColors.hue(r.source.name).withValues(alpha: 0.6),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SourceLine(r),
                                const SizedBox(height: 8),
                                Expanded(child: Text(r.title, style: t.headlineSmall, maxLines: 3, overflow: TextOverflow.ellipsis)),
                                Row(
                                  children: [
                                    Text('Read', style: AppTypography.sans(13, weight: FontWeight.w600, color: AppColors.accent)),
                                    const SizedBox(width: 5),
                                    const DoodleArrow(color: AppColors.accent, width: 16),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
