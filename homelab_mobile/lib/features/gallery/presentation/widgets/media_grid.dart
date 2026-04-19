import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/presentation/providers/media_provider.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/loading_shimmer.dart';
import 'package:homelab_mobile/features/gallery/presentation/widgets/media_tile.dart';

/// Responsive media grid that supports infinite scroll.
/// Intended as the body of a [CustomScrollView] via [SliverToBoxAdapter],
/// or used standalone.
class MediaGrid extends ConsumerStatefulWidget {
  const MediaGrid({super.key, this.crossAxisCount = 3});

  final int crossAxisCount;

  @override
  ConsumerState<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends ConsumerState<MediaGrid> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    // Trigger load when 200px from the bottom
    if (current >= maxScroll - 200) {
      ref.read(mediaNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(mediaNotifierProvider);

    return asyncState.when(
      loading: () => const LoadingShimmer(),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.read(mediaNotifierProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return const _EmptyView();
        }
        return _buildGrid(state);
      },
    );
  }

  Widget _buildGrid(MediaState state) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => MediaTile(
                item: state.items[index],
                allItems: state.items,
                index: index,
              ),
              childCount: state.items.length,
            ),
          ),
        ),

        // Pagination footer
        SliverToBoxAdapter(
          child: _PaginationFooter(state: state),
        ),
      ],
    );
  }
}

// ── Pagination footer ─────────────────────────────────────────────────────────

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state});

  final MediaState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '${state.total} items',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      );
    }
    return const SizedBox(height: 20);
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load media',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('No media found', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
