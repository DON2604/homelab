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
    final activeFilter =
        asyncState.valueOrNull?.activeFilter ?? MediaFilter.all;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        displacement: 80,
        onRefresh: () => ref.read(mediaNotifierProvider.notifier).refresh(),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _GalleryAppBar(
              total: total,
              innerBoxIsScrolled: innerBoxIsScrolled,
              activeFilter: activeFilter,
            ),
          ],
          body: const MediaGrid(),
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _GalleryAppBar extends ConsumerWidget {
  const _GalleryAppBar({
    required this.total,
    required this.innerBoxIsScrolled,
    required this.activeFilter,
  });

  final int total;
  final bool innerBoxIsScrolled;
  final MediaFilter activeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFiltered = activeFilter != MediaFilter.all;

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
                  activeFilter.label,
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
        // Show a highlighted filter icon when a filter is active
        IconButton(
          icon: Badge(
            isLabelVisible: isFiltered,
            backgroundColor: AppTheme.accent,
            smallSize: 8,
            child: const Icon(Icons.filter_list_rounded),
          ),
          tooltip: 'Filter',
          onPressed: () => _showFilterSheet(context, ref),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope(
        // Share the parent scope so the sheet can read/write the same provider
        parent: ProviderScope.containerOf(context),
        child: const _FilterSheet(),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncState = ref.watch(mediaNotifierProvider);
    final activeFilter =
        asyncState.valueOrNull?.activeFilter ?? MediaFilter.all;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          ...MediaFilter.values.map(
            (filter) => _FilterTile(
              filter: filter,
              isSelected: filter == activeFilter,
              onTap: () {
                ref
                    .read(mediaNotifierProvider.notifier)
                    .setFilter(filter);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Individual filter row ─────────────────────────────────────────────────────

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final MediaFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (filter) {
        MediaFilter.all => Icons.apps_rounded,
        MediaFilter.images => Icons.image_outlined,
        MediaFilter.videos => Icons.videocam_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _icon,
        color: isSelected ? AppTheme.accent : AppTheme.onSurface,
      ),
      title: Text(
        filter.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? AppTheme.accent : AppTheme.onBackground,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: AppTheme.accent)
          : null,
      onTap: onTap,
    );
  }
}
