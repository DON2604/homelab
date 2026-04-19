import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/constants/api_constants.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';
import 'package:homelab_mobile/features/gallery/domain/repositories/media_repository.dart';
import 'package:homelab_mobile/features/gallery/presentation/providers/provider_overrides.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Immutable state held by [MediaNotifier].
class MediaState {
  const MediaState({
    this.items = const [],
    this.total = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<MediaItem> items;
  final int total;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  int get currentSkip => items.length;

  MediaState copyWith({
    List<MediaItem>? items,
    int? total,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return MediaState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages gallery media list with pagination.
///
/// Usage:
/// ```dart
/// final state = ref.watch(mediaNotifierProvider);
/// ref.read(mediaNotifierProvider.notifier).loadMore();
/// ```
class MediaNotifier extends AsyncNotifier<MediaState> {
  late MediaRepository _repository;

  @override
  Future<MediaState> build() async {
    _repository = ref.watch(mediaRepositoryProvider);
    return _fetchFirstPage();
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Refreshes the list from the beginning.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage());
  }

  /// Appends the next page of items if more are available.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    // Mark as loading more without showing a full loading spinner
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.getMedia(
        skip: current.currentSkip,
        limit: ApiConstants.defaultPageSize,
      );

      final updated = current.copyWith(
        items: [...current.items, ...page.items],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
      state = AsyncData(updated);
    } catch (e) {
      // Keep existing items but report the error
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  Future<MediaState> _fetchFirstPage() async {
    final page = await _repository.getMedia(
      skip: 0,
      limit: ApiConstants.defaultPageSize,
    );
    return MediaState(
      items: page.items,
      total: page.total,
      hasMore: page.hasMore,
    );
  }
}

/// The primary provider for gallery state.
final mediaNotifierProvider =
    AsyncNotifierProvider<MediaNotifier, MediaState>(MediaNotifier.new);
