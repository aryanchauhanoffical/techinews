import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class LoadingShimmer extends StatelessWidget {
  final double? height;
  final double? width;
  final double radius;

  const LoadingShimmer({
    super.key,
    this.height,
    this.width,
    this.radius = AppSpacing.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
      highlightColor:
          isDark ? AppColors.darkBorder : AppColors.lightBorder,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class FeedCardShimmer extends StatelessWidget {
  const FeedCardShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(height: 220, radius: AppSpacing.radiusLg),
          const SizedBox(height: AppSpacing.lg),
          const LoadingShimmer(height: 24),
          const SizedBox(height: AppSpacing.sm),
          const LoadingShimmer(height: 24, width: 240),
          const SizedBox(height: AppSpacing.lg),
          const LoadingShimmer(height: 16),
          const SizedBox(height: AppSpacing.xs),
          const LoadingShimmer(height: 16),
          const SizedBox(height: AppSpacing.xs),
          const LoadingShimmer(height: 16, width: 180),
        ],
      ),
    );
  }
}
