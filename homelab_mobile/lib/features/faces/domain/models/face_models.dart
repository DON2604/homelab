import 'package:homelab_mobile/core/constants/api_constants.dart';

/// A cluster of similar faces, mapped to one person by DBSCAN.
class FaceCluster {
  const FaceCluster({
    required this.id,
    required this.name,
    required this.faceCount,
  });

  final int id;
  final String name;
  final int faceCount;

  factory FaceCluster.fromJson(Map<String, dynamic> json) {
    return FaceCluster(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Unknown',
      faceCount: (json['face_count'] as num).toInt(),
    );
  }
}

/// A single face occurrence within a person's cluster.
class FaceImage {
  const FaceImage({
    required this.filePath,
    required this.bbox,
  });

  /// Absolute path on the server, e.g. `/data/camera/IMG_xxx.jpg`
  final String filePath;

  /// Raw bbox string from the DB, e.g. `"[x, y, w, h, ...]"`
  final String bbox;

  String get thumbnailUrl => ApiConstants.faceImageThumbnailUrl(filePath);
  String get fullUrl => ApiConstants.faceImageFullUrl(filePath);

  /// Parses the bbox list from the JSON string stored in SQLite.
  /// Server stores bbox as a Python list repr or JSON array.
  List<double> get bboxValues {
    try {
      final cleaned = bbox
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => double.tryParse(e.trim()) ?? 0.0)
          .toList();
      return cleaned;
    } catch (_) {
      return [0, 0, 0, 0];
    }
  }

  factory FaceImage.fromJson(Map<String, dynamic> json) {
    return FaceImage(
      filePath: json['file_path'] as String,
      bbox: json['bbox']?.toString() ?? '[]',
    );
  }
}
