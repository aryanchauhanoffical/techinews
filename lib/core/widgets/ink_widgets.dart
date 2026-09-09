import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'doodle_figure.dart';
import 'doodles.dart';

/// Metadata line: BBC News · 12h · 3 sources
class MetaLine extends StatelessWidget {
  final List<String> parts;
  final Color color;
  final Widget? leading;
  const MetaLine(this.parts, {super.key, this.color = AppColors.inkMuted, this.leading});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        Flexible(
          child: Text(
            parts.where((p) => p.isNotEmpty).join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.kicker(color: color),
          ),
        ),
      ],
    );
  }
}

/// Section title with an optional leading icon, a marker underline, and a
/// right-hand "See all" action drawn with a doodle arrow.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? kicker;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? iconColor;
  final Color underline;
  const SectionHeader(this.title, {super.key, this.kicker, this.action, this.onAction, this.icon, this.iconColor, this.underline = AppColors.yellow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor ?? AppColors.ember),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Scribble(
                    color: underline,
                    thickness: 3,
                    inset: -4,
                    child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ),
                if (kicker != null) ...[
                  const SizedBox(height: 7),
                  Text(kicker!, style: AppTypography.kicker()),
                ],
              ],
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action!, style: AppTypography.sans(13.5, weight: FontWeight.w600, color: AppColors.accent)),
                    const SizedBox(width: 5),
                    const DoodleArrow(color: AppColors.accent, width: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small live dot used next to "updated" lines.
class LiveDot extends StatefulWidget {
  final Color color;
  const LiveDot({super.key, this.color = AppColors.accent});
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    }
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Composed empty / error state. Never a bare "No data". Centred, with a
/// hue-outlined icon disc and a couple of sparks so it feels drawn, not
/// defaulted.
class EmptyState extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final Color hue;
  final Figure? figure;
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = AppIcons.inbox,
    this.hue = AppColors.accent,
    this.figure,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.xxl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (figure != null)
            DoodleFigure(figure!, hue: hue, height: 170)
          else
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: hue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: hue, width: 1.6),
                  ),
                  child: Icon(icon, size: 32, color: hue),
                ),
                const Positioned(top: 0, right: 4, child: Spark(size: 16)),
                const Positioned(bottom: 6, left: 0, child: Spark(size: 10, color: AppColors.pink, turn: 0.4)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Numeric score in mono with a tiny accent tick. Used for trend scores.
class ScoreMark extends StatelessWidget {
  final int score;
  const ScoreMark(this.score, {super.key});

  @override
  Widget build(BuildContext context) {
    final hot = score >= 80;
    final color = hot ? AppColors.ember : AppColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(hot ? AppIcons.flame : AppIcons.trending, size: 14, color: color),
        const SizedBox(width: 3),
        Text('$score', style: AppTypography.mono(12, weight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// Hairline divider that respects the page gutter.
class GutterDivider extends StatelessWidget {
  const GutterDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Divider(),
      );
}

/// Category fallback artwork. Eleven pop-art illustrations generated to the
/// asset-rules prompt; picked by the story's first topic.
String fallbackAsset(String? category) {
  final c = (category ?? '').toLowerCase();
  String key = 'general';
  if (c.contains('ai') || c.contains('intelligence') || c.contains('llm') || c.contains('model')) {
    key = 'ai';
  } else if (c.contains('open source') || c.contains('github') || c.contains('release')) {
    key = 'open-source';
  } else if (c.contains('startup') || c.contains('launch') || c.contains('product')) {
    key = 'startups';
  } else if (c.contains('secur') || c.contains('privacy')) {
    key = 'security';
  } else if (c.contains('hardware') || c.contains('chip') || c.contains('nvidia')) {
    key = 'hardware';
  } else if (c.contains('space')) {
    key = 'space';
  } else if (c.contains('web') || c.contains('developer')) {
    key = 'web';
  } else if (c.contains('mobile') || c.contains('apple') || c.contains('android')) {
    key = 'mobile';
  } else if (c.contains('research') || c.contains('paper') || c.contains('science')) {
    key = 'research';
  } else if (c.contains('fund') || c.contains('finance') || c.contains('money')) {
    key = 'funding';
  }
  return 'assets/fallbacks/fallback-$key.jpg';
}

/// Network image. When there is no image, or it fails, the category's
/// fallback illustration takes its place. A designed fallback, never a
/// broken-image glyph.
class InkImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final double radius;
  final BoxFit fit;
  final String? label;
  /// Hide the small source caption in the fallback tile (used under app bars).
  final bool quiet;
  /// Story category, used to choose the fallback illustration.
  final String? category;
  const InkImage(this.url, {super.key, this.height, this.width, this.radius = AppSpacing.radiusLg, this.fit = BoxFit.cover, this.label, this.quiet = false, this.category});

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      fallbackAsset(category ?? label),
      height: height,
      width: width,
      fit: BoxFit.cover,
      semanticLabel: label,
      errorBuilder: (_, _, _) => _Tile(height: height, width: width, label: label, quiet: quiet),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (url == null || url!.isEmpty)
          ? fallback
          : Image.network(
              url!,
              height: height,
              width: width,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  final double? height;
  final double? width;
  final String? label;
  final bool quiet;
  const _Tile({this.height, this.width, this.label, this.quiet = false});

  @override
  Widget build(BuildContext context) {
    final initial = (label ?? '').trim();
    final mono = initial.isEmpty ? '' : initial[0].toUpperCase();
    final small = (height ?? 200) < 100;
    return Container(
      height: height,
      width: width,
      color: AppColors.surfaceRaised,
      child: Stack(
        children: [
          Positioned(
            right: small ? -6 : -10,
            bottom: small ? -14 : -26,
            child: Text(
              mono,
              style: AppTypography.serif(small ? 64 : 150, color: AppColors.hairlineStrong),
            ),
          ),
          if (!small && !quiet && initial.isNotEmpty)
            Positioned(
              left: 14,
              top: 12,
              child: Text(initial, style: AppTypography.kicker(color: AppColors.inkMuted)),
            ),
        ],
      ),
    );
  }
}

/// Simple Icons slug for sources we recognise, so brand marks are the
/// official glyphs rather than a scraped favicon. Null means "no brand".
String? brandSlug(String name) {
  final n = name.toLowerCase();
  const table = <String, String>{
    'github': 'github',
    'hacker news': 'ycombinator',
    'reddit': 'reddit',
    'arxiv': 'arxiv',
    'hugging face': 'huggingface',
    'openai': 'openai',
    'anthropic': 'anthropic',
    'google': 'google',
    'deepmind': 'googledeepmind',
    'meta': 'meta',
    'microsoft': 'microsoft',
    'apple': 'apple',
    'nvidia': 'nvidia',
    'techcrunch': 'techcrunch',
    'the verge': 'theverge',
    'wired': 'wired',
    'ars technica': 'arstechnica',
    'product hunt': 'producthunt',
    'medium': 'medium',
    'substack': 'substack',
    'youtube': 'youtube',
    'mozilla': 'mozilla',
    'vercel': 'vercel',
    'cloudflare': 'cloudflare',
    'stripe': 'stripe',
    'mistral': 'mistralai',
    'lobste.rs': 'lobsters',
    'dev.to': 'devdotto',
    'claude code': 'anthropic',
  };
  for (final e in table.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return null;
}

/// Round source mark: an official brand glyph (Simple Icons) when the
/// source is a known brand, else the favicon we scraped, else the initial
/// on a raised disc.
class SourceAvatar extends StatelessWidget {
  final String name;
  final String? iconUrl;
  final double size;
  const SourceAvatar(this.name, {super.key, this.iconUrl, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.surfaceRaised, shape: BoxShape.circle),
      child: Text(initial, style: AppTypography.sans(size * 0.5, weight: FontWeight.w700, height: 1, color: AppColors.inkSecondary)),
    );
    final slug = brandSlug(name);
    if (slug != null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.2),
        decoration: const BoxDecoration(color: AppColors.surfaceRaised, shape: BoxShape.circle),
        child: SvgPicture.network(
          'https://cdn.simpleicons.org/$slug/F8FAFC',
          semanticsLabel: name,
          placeholderBuilder: (_) => const SizedBox.shrink(),
        ),
      );
    }
    if (iconUrl == null || iconUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// "Trending #1" sticker over imagery.
class TrendBadge extends StatelessWidget {
  final String label;
  final bool hot;
  const TrendBadge(this.label, {super.key, this.hot = true});
  @override
  Widget build(BuildContext context) => Sticker(label, color: hot ? AppColors.yellow : AppColors.accent, icon: hot ? AppIcons.flame : null);
}

/// Icon + count triplets under a headline: score, sources, comments.
class StatRow extends StatelessWidget {
  final List<(IconData, String)> stats;
  const StatRow(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in stats) ...[
          Icon(s.$1, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 4),
          Text(s.$2, style: AppTypography.mono(12, color: AppColors.inkMuted)),
          const SizedBox(width: 14),
        ],
      ],
    );
  }
}

/// Outlined search field used as a tap target that opens the search screen.
class SearchBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final String hint;
  const SearchBarButton({super.key, required this.onTap, this.hint = 'Search tech news, companies, topics'});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.hairlineStrong, width: 1.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(AppIcons.search, size: 20, color: AppColors.inkSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.sans(14, color: AppColors.inkMuted))),
              const Icon(AppIcons.filter, size: 18, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab strip. The active tab is a filled blue sticker; the others are
/// plain labels. Colour animates so switching reads as a slide, not a pop.
class TabStrip extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const TabStrip({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final on = i == index;
          return Semantics(
            selected: on,
            button: true,
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  labels[i],
                  style: on
                      ? AppTypography.serif(14, weight: FontWeight.w700, height: 1, color: AppColors.onAccent)
                      : AppTypography.sans(14, weight: FontWeight.w500, height: 1, color: AppColors.inkSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
