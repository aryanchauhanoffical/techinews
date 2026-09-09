import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../data/models/social_post.dart';

class DiscussionCard extends StatelessWidget {
  final SocialPost post;
  const DiscussionCard(this.post, {super.key});

  String get _platform => switch (post.platform) {
        SocialPlatform.reddit => 'Reddit',
        SocialPlatform.twitter => 'X',
        SocialPlatform.hackerNews => 'Hacker News',
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(post.url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_platform, style: AppTypography.kicker(color: AppColors.accent)),
                const SizedBox(width: 10),
                Expanded(child: Text(post.authorHandle ?? post.author, style: AppTypography.mono(11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(FormatShort.short(post.postedAt), style: AppTypography.kicker()),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(post.content, style: t.bodyMedium?.copyWith(color: AppColors.ink), maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.sm),
            Text('${Format.compactNumber(post.upvotes)} points  ·  ${Format.compactNumber(post.comments)} comments', style: AppTypography.mono(11)),
          ],
        ),
      ),
    );
  }
}
