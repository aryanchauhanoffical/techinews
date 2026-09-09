import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/doodles.dart';
import '../../../../data/models/article.dart';
import '../../../../data/models/github_repo.dart';

/// Repo card the way a developer scans it: owner/name, description, language
/// dot, stars, forks, and a "Trending" sticker when stars are moving. Tapping
/// opens the story when one is attached, otherwise the repo itself.
class RepoCard extends StatelessWidget {
  final GithubRepo repo;
  final Article? story;
  const RepoCard(this.repo, {super.key, this.story});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final parts = repo.fullName.split('/');
    final trending = repo.starsThisWeek > 0;
    final hook = repo.hook;
    final sub = hook != null ? (repo.pitch ?? repo.description) : repo.description;
    return PopCard(
      hue: AppColors.hairlineStrong,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      onTap: () => story != null ? context.push(AppRoutes.articlePath(story!.id)) : launchUrl(Uri.parse(repo.url), mode: LaunchMode.externalApplication),
      child: Stack(
        children: [
          Positioned(right: -6, top: -6, child: Icon(AppIcons.code, size: 64, color: AppColors.green.withValues(alpha: 0.10))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.code, size: 16, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTypography.serif(15, weight: FontWeight.w700, height: 1.1, color: AppColors.ink),
                        children: [
                          if (parts.length > 1) TextSpan(text: '${parts.first} / ', style: AppTypography.sans(13.5, weight: FontWeight.w500, color: AppColors.inkMuted)),
                          TextSpan(text: parts.last),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open on GitHub',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => launchUrl(Uri.parse(repo.url), mode: LaunchMode.externalApplication),
                    icon: const Icon(AppIcons.external, size: 16, color: AppColors.inkMuted),
                  ),
                ],
              ),
              if (hook != null) ...[
                const SizedBox(height: 8),
                // The sell. Big, display voice, colour-coded when it replaces something famous.
                Text(hook, style: AppTypography.serif(19, weight: FontWeight.w800, height: 1.15, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (repo.altTo != null && repo.altTo!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  HueTag('Free alternative to ${repo.altTo}', hue: AppColors.pink, dense: true),
                ],
              ],
              if (sub.isNotEmpty) ...[
                SizedBox(height: hook != null ? 6 : 4),
                Text(sub, style: t.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(AppIcons.star, size: 15, color: AppColors.yellow),
                  const SizedBox(width: 4),
                  Text(Format.compactNumber(repo.stars), style: AppTypography.mono(12.5, weight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(width: 14),
                  const Icon(AppIcons.fork, size: 15, color: AppColors.inkMuted),
                  const SizedBox(width: 4),
                  Text(Format.compactNumber(repo.forks), style: AppTypography.mono(12.5, color: AppColors.inkSecondary)),
                  if (repo.language != null) ...[
                    const SizedBox(width: 14),
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: AppColors.language(repo.language), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(repo.language!, style: AppTypography.mono(12.5, color: AppColors.inkSecondary)),
                  ],
                  const Spacer(),
                  if (trending)
                    HueTag('Trending  +${Format.compactNumber(repo.starsThisWeek)}', hue: AppColors.green, dense: true)
                  else if (repo.lastCommit != null)
                    Text('Pushed ${FormatShort.short(repo.lastCommit!)} ago', style: AppTypography.kicker()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
