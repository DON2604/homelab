import 'package:homelab_mobile/features/gallery/data/datasources/media_remote_datasource.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';
import 'package:homelab_mobile/features/gallery/domain/repositories/media_repository.dart';

/// Concrete implementation of [MediaRepository] backed by [MediaRemoteDataSource].
class MediaRepositoryImpl implements MediaRepository {
  const MediaRepositoryImpl(this._dataSource);

  final MediaRemoteDataSource _dataSource;

  @override
  Future<MediaPage> getMedia({
    int skip = 0,
    int limit = 50,
    String? filterType,
  }) {
    return _dataSource.fetchMedia(
      skip: skip,
      limit: limit,
      filterType: filterType,
    );
  }
}
