import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/doodles.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../services/providers.dart';
import '../../article/presentation/widgets/repo_card.dart';

/// Fixed magazine sections. Counts come from the live topic index when a
/// matching topic exists; the search query is what the card opens.
class _Section {
  final String name;
  final String blurb;
  final IconData icon;
  final Color hue;
  final String query;
  const _Section(this.name, this.blurb, this.icon, this.hue, this.query);
}

const _sections = [
  _Section('Trending', 'What moved this hour', AppIcons.flame, AppColors.orange, 'trending'),
  _Section('AI', 'Models, agents, labs', AppIcons.ai, AppColors.accent, 'AI'),
  _Section('Startups', 'Launches and funding', AppIcons.startups, AppColors.pink, 'startups'),
  _Section('Open Source', 'Repos crossing the line', AppIcons.code, AppColors.green, 'open source'),
  _Section('Cybersecurity', 'Breaches and patches', AppIcons.security, AppColors.yellow, 'security'),
  _Section('Space', 'Launches and orbit', AppIcons.space, AppColors.purple, 'space'),
  _Section('Hardware', 'Chips and devices', AppIcons.hardware, AppColors.cyan, 'hardware'),
  _Section('Developer Tools', 'Editors, CLIs, infra', AppIcons.devtools, AppColors.green, 'developer tools'),
  _Section('Research', 'arXiv and papers', AppIcons.research, AppColors.purple, 'research'),
];

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(trendingTopicsProvider);
    final repos = ref.watch(trendingReposProvider);
    final funding = ref.watch(fundingEventsProvider);
    final t = Theme.of(context).textTheme;
    final counts = <String, int>{};
    for (final x in topics.valueOrNull ?? const []) {
      counts[x.name.toLowerCase()] = x.articleCount;
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceRaised,
        onRefresh: () async {
          ref.invalidate(trendingTopicsProvider);
          ref.invalidate(trendingReposProvider);
          ref.invalidate(fundingEventsProvider);
        },
        child: LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth > 600 ? 3 : 2;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Discover', style: t.headlineLarge),
                              const SizedBox(width: 8),
                              const Padding(padding: EdgeInsets.only(bottom: 10), child: Spark(size: 14, color: AppColors.pink, turn: 0.3)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Explore the magazine by section', style: AppTypography.kicker()),
                          const SizedBox(height: AppSpacing.lg),
                          SearchBarButton(onTap: () => context.push(AppRoutes.search), hint: 'Search stories, repos, companies'),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: _sections.length,
                    itemBuilder: (_, i) {
                      final s = _sections[i];
                      final n = counts[s.name.toLowerCase()] ?? counts[s.query.toLowerCase()];
                      return _SectionCard(
                        section: s,
                        count: n,
                        onTap: () => context.push('${AppRoutes.search}?q=${Uri.encodeComponent(s.query)}'),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SectionHeader('Repos worth watching', icon: AppIcons.github, iconColor: AppColors.ink, underline: AppColors.green, kicker: 'From this fortnight\'s stories')),
                repos.when(
                  loading: () => const SliverToBoxAdapter(child: StoryRowSkeleton()),
                  error: (_, _) => const SliverToBoxAdapter(child: _Unavailable()),
                  data: (items) => items.isEmpty
                      ? const SliverToBoxAdapter(child: _Unavailable(text: 'No repos in the current window.'))
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                          sliver: SliverList.list(children: [
                            for (final r in items.take(6)) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: RepoCard(r)),
                          ]),
                        ),
                ),
                const SliverToBoxAdapter(child: SectionHeader('Funding', icon: AppIcons.finance, iconColor: AppColors.yellow, underline: AppColors.yellow, kicker: 'Rounds mentioned in the last 10 days')),
                funding.when(
                  loading: () => const SliverToBoxAdapter(child: StoryRowSkeleton()),
                  error: (_, _) => const SliverToBoxAdapter(child: _Unavailable()),
                  data: (items) => items.isEmpty
                      ? const SliverToBoxAdapter(child: _Unavailable(text: 'No funding rounds spotted yet.'))
                      : SliverList.list(children: [
                          for (final f in items) ...[
                            InkWell(
                              onTap: () => context.push(AppRoutes.articlePath(f.id)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(f.companyName, style: t.titleLarge),
                                          const SizedBox(height: 2),
                                          Text(f.description ?? '', style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(f.amountUsd > 0 ? Format.money(f.amountUsd) : 'undisclosed', style: AppTypography.serif(16, weight: FontWeight.w700, color: AppColors.yellow)),
                                        Text(f.round, style: AppTypography.kicker()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const GutterDivider(),
                          ],
                        ]),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final String text;
  const _Unavailable({this.text = 'Could not load this section.'});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}

/// Magazine section card: hue outline, big faded glyph, name, blurb, count.
class _SectionCard extends StatelessWidget {
  final _Section section;
  final int? count;
  final VoidCallback onTap;
  const _SectionCard({required this.section, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = section;
    return PressScale(
      onTap: onTap,
      child: PopCard(
        hue: s.hue.withValues(alpha: 0.6),
        fill: Color.alphaBlend(s.hue.withValues(alpha: 0.07), AppColors.surface),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned(right: -12, bottom: -16, child: Icon(s.icon, size: 76, color: s.hue.withValues(alpha: 0.12))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(s.icon, size: 22, color: s.hue),
                    const Spacer(),
                    if (count != null) HueTag('$count', hue: s.hue, dense: true),
                  ],
                ),
                const Spacer(),
                Text(s.name, style: AppTypography.serif(16, weight: FontWeight.w700, height: 1.15)),
                const SizedBox(height: 2),
                Text(s.blurb, style: AppTypography.sans(12, color: AppColors.inkMuted, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
