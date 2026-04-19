import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/video_player_widget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';

/// Full-screen viewer for images (pinch-to-zoom) and videos (streaming player).
/// Accepts a list of items and an initial index to enable swipe navigation.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<MediaItem> items;
  final int initialIndex;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showBars = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleBars() => setState(() => _showBars = !_showBars);

  MediaItem get _current => widget.items[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showBars ? _buildAppBar() : null,
      bottomNavigationBar:
          _showBars ? _buildInfoBar(context) : null,
      body: _buildPageView(),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withAlpha(100),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '${_currentIndex + 1} / ${widget.items.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onPressed: () => _showDetailsSheet(context),
        ),
      ],
    );
  }

  // ── Info bar ────────────────────────────────────────────────────────────

  Widget _buildInfoBar(BuildContext context) {
    final item = _current;
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(item.modifiedAt);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withAlpha(140),
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              Icon(
                item.isVideo
                    ? Icons.videocam_rounded
                    : Icons.image_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.filename,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$dateStr · ${item.formattedSize}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page view ───────────────────────────────────────────────────────────

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.items.length,
      onPageChanged: (i) => setState(() => _currentIndex = i),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        if (item.isVideo) {
          return GestureDetector(
            onTap: _toggleBars,
            child: Center(child: VideoPlayerWidget(item: item)),
          );
        }
        return _ImagePage(item: item, onTap: _toggleBars);
      },
    );
  }

  // ── Details sheet ───────────────────────────────────────────────────────

  void _showDetailsSheet(BuildContext context) {
    final item = _current;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailsSheet(item: item),
    );
  }
}

// ── Image page with photo_view ────────────────────────────────────────────────

class _ImagePage extends StatelessWidget {
  const _ImagePage({required this.item, required this.onTap});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'media_${item.filename}',
      child: GestureDetector(
        onTap: onTap,
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(item.fullUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (_, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded /
                      (event.expectedTotalBytes ?? 1),
              color: AppTheme.accent,
              strokeWidth: 2,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined,
                color: Colors.white38, size: 64),
          ),
        ),
      ),
    );
  }
}

// ── Details sheet ─────────────────────────────────────────────────────────────

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('MMMM d, yyyy · HH:mm:ss').format(item.modifiedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Details', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.insert_drive_file_outlined, label: 'Name', value: item.filename),
          _DetailRow(
              icon: item.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
              label: 'Type',
              value: item.type.toUpperCase()),
          _DetailRow(icon: Icons.data_usage_rounded, label: 'Size', value: item.formattedSize),
          _DetailRow(icon: Icons.schedule_rounded, label: 'Modified', value: dateStr),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.onBackground),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
