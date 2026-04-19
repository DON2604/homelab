import 'package:homelab_mobile/core/constants/api_constants.dart';

/// Represents a single media item returned by `GET /media/`.
class MediaItem {
  const MediaItem({
    required this.filename,
    required this.type,
    required this.size,
    required this.mtime,
  });

  /// Original filename, e.g. `IMG_20240101_120000.jpg`
  final String filename;

  /// `'image'` or `'video'`
  final String type;

  /// File size in bytes
  final int size;

  /// Modification timestamp (Unix epoch seconds, fractional)
  final double mtime;

  // ── Computed URLs ──────────────────────────────────────────────────────
  String get thumbnailUrl => ApiConstants.thumbnailUrl(filename);
  String get fullUrl => ApiConstants.fullUrl(filename);
  String get streamUrl => ApiConstants.streamUrl(filename);

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  /// Human-readable file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Modification date as [DateTime]
  DateTime get modifiedAt =>
      DateTime.fromMillisecondsSinceEpoch((mtime * 1000).round());

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      filename: json['filename'] as String,
      type: json['type'] as String,
      size: (json['size'] as num).toInt(),
      mtime: (json['mtime'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          filename == other.filename;

  @override
  int get hashCode => filename.hashCode;
}

/// Paginated response from `GET /media/`
class MediaPage {
  const MediaPage({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<MediaItem> items;
  final int total;
  final int skip;
  final int limit;

  bool get hasMore => skip + limit < total;

  factory MediaPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>;
    return MediaPage(
      items: rawList
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      skip: (json['skip'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );
  }
}
