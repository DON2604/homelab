import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/constants/api_constants.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';
import 'package:homelab_mobile/features/gallery/domain/repositories/media_repository.dart';
import 'package:homelab_mobile/features/gallery/presentation/providers/provider_overrides.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

/// Represents the active media type filter.
enum MediaFilter {
  all,
  images,
  videos;

  /// The value forwarded to the server as `filter_type`, or `null` for all.
  String? get queryValue => switch (this) {
        MediaFilter.all => null,
        MediaFilter.images => 'image',
        MediaFilter.videos => 'video',
      };

  String get label => switch (this) {
        MediaFilter.all => 'Photos & Videos',
        MediaFilter.images => 'Photos',
        MediaFilter.videos => 'Videos',
      };
}

// ── State ─────────────────────────────────────────────────────────────────────

/// Immutable state held by [MediaNotifier].
class MediaState {
  const MediaState({
    this.items = const [],
    this.total = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.activeFilter = MediaFilter.all,
    this.error,
  });

  final List<MediaItem> items;
  final int total;
  final bool isLoadingMore;
  final bool hasMore;
  final MediaFilter activeFilter;
  final String? error;

  int get currentSkip => items.length;

  MediaState copyWith({
    List<MediaItem>? items,
    int? total,
    bool? isLoadingMore,
    bool? hasMore,
    MediaFilter? activeFilter,
    String? error,
  }) {
    return MediaState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      activeFilter: activeFilter ?? this.activeFilter,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Manages gallery media list with pagination and server-side type filtering.
///
/// Usage:
/// ```dart
/// final state = ref.watch(mediaNotifierProvider);
/// ref.read(mediaNotifierProvider.notifier).setFilter(MediaFilter.videos);
/// ref.read(mediaNotifierProvider.notifier).loadMore();
/// ```
class MediaNotifier extends AsyncNotifier<MediaState> {
  late MediaRepository _repository;

  @override
  Future<MediaState> build() async {
    _repository = ref.watch(mediaRepositoryProvider);
    return _fetchFirstPage(filter: MediaFilter.all);
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Applies a new filter and reloads items from page 1.
  Future<void> setFilter(MediaFilter filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(filter: filter));
  }

  /// Refreshes the list from the beginning, keeping the current filter.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    final filter = current?.activeFilter ?? MediaFilter.all;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(filter: filter));
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
        filterType: current.activeFilter.queryValue,
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

  Future<MediaState> _fetchFirstPage({required MediaFilter filter}) async {
    final page = await _repository.getMedia(
      skip: 0,
      limit: ApiConstants.defaultPageSize,
      filterType: filter.queryValue,
    );
    return MediaState(
      items: page.items,
      total: page.total,
      hasMore: page.hasMore,
      activeFilter: filter,
    );
  }
}

/// The primary provider for gallery state.
final mediaNotifierProvider =
    AsyncNotifierProvider<MediaNotifier, MediaState>(MediaNotifier.new);

/// Provider to check if the server is online.
final serverStatusProvider = StreamProvider.autoDispose<bool>((ref) async* {
  Future<bool> checkStatus() async {
    try {
      final response = await http
          .get(Uri.parse('https://hip-trim-dirt-duration.trycloudflare.com/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['status'] == 'ok';
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  // Initial check right away
  yield await checkStatus();

  // Then check every 20 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 20))) {
    yield await checkStatus();
  }
});
