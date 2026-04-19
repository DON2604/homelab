import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/presentation/providers/media_provider.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/media_grid.dart';

/// Main gallery screen — a Material 3 scaffold with a frosted-glass SliverAppBar
/// and an infinite-scroll photo/video grid.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mediaNotifierProvider);
    final total = asyncState.valueOrNull?.total ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        displacement: 80,
        onRefresh: () => ref.read(mediaNotifierProvider.notifier).refresh(),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _GalleryAppBar(total: total, innerBoxIsScrolled: innerBoxIsScrolled),
          ],
          body: const MediaGrid(),
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _GalleryAppBar extends StatelessWidget {
  const _GalleryAppBar({
    required this.total,
    required this.innerBoxIsScrolled,
  });

  final int total;
  final bool innerBoxIsScrolled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      forceElevated: innerBoxIsScrolled,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withAlpha(230),
                    AppTheme.background.withAlpha(120),
                  ],
                ),
              ),
            ),
            titlePadding:
                const EdgeInsetsDirectional.only(start: 20, bottom: 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photos',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                if (total > 0)
                  Text(
                    '$total items',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filter',
          onPressed: () => _showFilterSheet(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ── Filter bottom sheet (placeholder) ────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Show', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _FilterChip(label: 'All', selected: true, icon: Icons.apps_rounded),
          _FilterChip(
              label: 'Photos',
              selected: false,
              icon: Icons.image_outlined),
          _FilterChip(
              label: 'Videos',
              selected: false,
              icon: Icons.videocam_outlined),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.icon,
  });

  final String label;
  final bool selected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: selected ? AppTheme.accent : AppTheme.onSurface,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? AppTheme.accent : AppTheme.onBackground,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppTheme.accent)
          : null,
      onTap: () => Navigator.pop(context),
    );
  }
}
