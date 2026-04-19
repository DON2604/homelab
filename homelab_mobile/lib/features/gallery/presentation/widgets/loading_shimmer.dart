import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';

/// A full-grid shimmer skeleton shown during the initial load.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, this.crossAxisCount = 3});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surface,
      highlightColor: AppTheme.surfaceVariant,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: 30,
        itemBuilder: (context, index) => const _ShimmerTile(),
      ),
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        // No borderRadius to match the tight grid look
      ),
    );
  }
}
