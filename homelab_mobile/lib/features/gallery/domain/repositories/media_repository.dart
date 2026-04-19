import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';

/// Abstract contract for fetching media items.
/// Implementations live in the data layer.
abstract class MediaRepository {
  /// Fetches a page of media items.
  ///
  /// [skip] — number of items to skip (offset)
  /// [limit] — max items to return (1–100)
  Future<MediaPage> getMedia({int skip = 0, int limit = 50});
}
