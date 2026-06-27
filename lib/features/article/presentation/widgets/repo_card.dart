import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../data/models/github_repo.dart';

class RepoCard extends StatelessWidget {
  final GithubRepo repo;
  const RepoCard({super.key, required this.repo});

  Future<void> _open() async {
    final uri = Uri.parse(repo.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PressScale(
      onTap: _open,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
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
                const Icon(Icons.code_rounded,
                    size: 16, color: AppColors.brandAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    repo.fullName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (repo.starsThisWeek > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up,
                            size: 12, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          '+${Format.compactNumber(repo.starsThisWeek)}',
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              repo.description,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (repo.language != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(repo.language!,
                      style: theme.textTheme.labelSmall),
                  const SizedBox(width: AppSpacing.md),
                ],
                const Icon(Icons.star_rounded,
                    size: 14, color: AppColors.brandHighlight),
                const SizedBox(width: 3),
                Text(Format.compactNumber(repo.stars),
                    style: theme.textTheme.labelSmall),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.call_split_rounded,
                    size: 13,
                    color: theme.textTheme.labelSmall?.color),
                const SizedBox(width: 3),
                Text(Format.compactNumber(repo.forks),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
