import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Skeletons that match the shapes they stand in for.
class Skeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const Skeleton({super.key, required this.height, this.width, this.radius = AppSpacing.radiusSm});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerBlock extends StatelessWidget {
  final Widget child;
  const ShimmerBlock({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceRaised,
      highlightColor: AppColors.hairlineStrong,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A feed row placeholder: kicker, two headline lines, one summary line.
class StoryRowSkeleton extends StatelessWidget {
  final bool withImage;
  const StoryRowSkeleton({super.key, this.withImage = false});

  @override
  Widget build(BuildContext context) {
    return ShimmerBlock(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (withImage) ...[
              const Skeleton(height: 180, radius: AppSpacing.radiusLg),
              const SizedBox(height: AppSpacing.md),
            ],
            const Skeleton(height: 10, width: 120),
            const SizedBox(height: AppSpacing.md),
            const Skeleton(height: 18),
            const SizedBox(height: AppSpacing.sm),
            const Skeleton(height: 18, width: 220),
            const SizedBox(height: AppSpacing.md),
            const Skeleton(height: 12, width: 260),
          ],
        ),
      ),
    );
  }
}
