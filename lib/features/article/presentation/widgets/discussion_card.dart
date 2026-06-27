import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../data/models/social_post.dart';

class DiscussionCard extends StatelessWidget {
  final SocialPost post;
  const DiscussionCard({super.key, required this.post});

  Future<void> _open() async {
    final uri = Uri.parse(post.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _platformName {
    switch (post.platform) {
      case SocialPlatform.reddit:
        return 'Reddit';
      case SocialPlatform.twitter:
        return 'X';
      case SocialPlatform.hackerNews:
        return 'Hacker News';
    }
  }

  IconData get _platformIcon {
    switch (post.platform) {
      case SocialPlatform.reddit:
        return Icons.forum_rounded;
      case SocialPlatform.twitter:
        return Icons.alternate_email_rounded;
      case SocialPlatform.hackerNews:
        return Icons.bolt_rounded;
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_platformIcon,
                          size: 11, color: AppColors.brandAccent),
                      const SizedBox(width: 4),
                      Text(
                        _platformName,
                        style: const TextStyle(
                            color: AppColors.brandAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    post.authorHandle ?? post.author,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(Format.relativeTime(post.postedAt),
                    style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 3),
                Text(Format.compactNumber(post.upvotes),
                    style: theme.textTheme.labelSmall),
                const SizedBox(width: AppSpacing.lg),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 13, color: theme.textTheme.labelSmall?.color),
                const SizedBox(width: 4),
                Text(Format.compactNumber(post.comments),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
