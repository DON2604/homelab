import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';
import 'package:homelab_mobile/features/gallery/presentation/screens/viewer_screen.dart';
import 'package:shimmer/shimmer.dart';

/// A single tile in the media grid. Shows a thumbnail with a video badge
/// overlay when the item is a video, plus a Hero animation to the viewer.
class MediaTile extends StatelessWidget {
  const MediaTile({
    super.key,
    required this.item,
    required this.allItems,
    required this.index,
  });

  final MediaItem item;
  final List<MediaItem> allItems;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Hero(
        tag: 'media_${item.filename}',
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ThumbnailImage(item: item),
            if (item.isVideo) const _VideoOverlay(),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ViewerScreen(
          items: allItems,
          initialIndex: index,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }
}

// ── Thumbnail image ───────────────────────────────────────────────────────────

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: item.thumbnailUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppTheme.surface,
        highlightColor: AppTheme.surfaceVariant,
        child: Container(color: AppTheme.surface),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.surfaceVariant,
        child: const Icon(Icons.broken_image_outlined, color: Colors.white38),
      ),
    );
  }
}

// ── Video overlay badge ───────────────────────────────────────────────────────

class _VideoOverlay extends StatelessWidget {
  const _VideoOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Subtle gradient at bottom for icon contrast
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(160),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Play icon badge (top-right)
        Positioned(
          top: 5,
          right: 5,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.videocam_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
        // Play icon (center)
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 32,
            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}
