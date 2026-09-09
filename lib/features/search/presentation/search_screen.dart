import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/doodle_figure.dart';
import '../../../core/widgets/ink_widgets.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/topic_chip.dart';
import '../../../services/providers.dart';
import '../../feed/presentation/widgets/feed_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _c = TextEditingController(text: widget.initialQuery ?? ref.read(searchQueryProvider));
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery?.trim();
    if (q != null && q.isNotEmpty) {
      Future.microtask(() => ref.read(searchQueryProvider.notifier).state = q);
    }
  }

  static const _suggestions = ['Anthropic', 'OpenAI', 'agents', 'Rust', 'funding', 'llama.cpp', 'security'];

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = v.trim();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: TextField(
          controller: _c,
          autofocus: q.isEmpty,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search stories',
            isDense: true,
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () {
                      _c.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
          ),
        ),
        actions: const [SizedBox(width: AppSpacing.sm)],
      ),
      body: q.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Try searching for', style: AppTypography.kicker()),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in _suggestions)
                        TopicChip(
                          label: s,
                          onTap: () {
                            _c.text = s;
                            ref.read(searchQueryProvider.notifier).state = s;
                          },
                        ),
                    ],
                  ),
                ],
              ),
            )
          : results.when(
              loading: () => const Column(children: [StoryRowSkeleton(), StoryRowSkeleton()]),
              error: (_, _) => EmptyState(
                icon: AppIcons.offline,
                title: 'Search is unavailable',
                body: 'The server did not answer. Try again in a moment.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(searchResultsProvider),
              ),
              data: (items) => items.isEmpty
                  ? EmptyState(icon: AppIcons.searchOff, figure: Figure.float, hue: AppColors.cyan, title: 'No stories match "$q"', body: 'Try a company, a repo name, or a broader topic.')
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, _) => const GutterDivider(),
                      itemBuilder: (_, i) => i == 0
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
                              child: Text('${items.length} RESULTS', style: AppTypography.kicker(color: AppColors.inkMuted)),
                            )
                          : StoryRow(items[i - 1]),
                    ),
            ),
    );
  }
}
