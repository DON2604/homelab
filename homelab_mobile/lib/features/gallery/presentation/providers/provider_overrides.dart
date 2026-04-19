import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/features/gallery/data/datasources/media_remote_datasource.dart';
import 'package:homelab_mobile/features/gallery/data/repositories/media_repository_impl.dart';
import 'package:homelab_mobile/features/gallery/domain/repositories/media_repository.dart';

/// Provides the raw HTTP data source.
final mediaDatasourceProvider = Provider<MediaRemoteDataSource>(
  (ref) => MediaRemoteDataSource(),
);

/// Provides the repository bound to the data source above.
final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(ref.watch(mediaDatasourceProvider)),
);
