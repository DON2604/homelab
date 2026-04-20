import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/presentation/providers/media_provider.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/media_grid.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/logs_drawer.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/waveprogress.dart';

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
      drawer: const LogsDrawer(),
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
    final serverStatusAsync = ref.watch(serverStatusProvider);

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      forceElevated: innerBoxIsScrolled,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
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
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeFilter.label,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              serverStatusAsync.when(
                data: (isOnline) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                loading: () => Text(
                  'Checking...',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurface.withOpacity(0.5),
                  ),
                ),
                error: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0) ...[
                Text(
                  ' • ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  '$total items',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    WavyProgressIndicator(progress: 0.4, color: Colors.purple),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/coming.gif',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0%  AI engine',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Logs',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.outline.withOpacity(0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search media...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurface.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: AppTheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
        ),
      ),
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
                ref.read(mediaNotifierProvider.notifier).setFilter(filter);
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
