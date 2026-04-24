/// Central place for all API base URLs and endpoint builders.
/// Change [baseUrl] to point to a different server.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.0.207:8000';
  static const String mediaPrefix = '/media';
  static const String logsPrefix = '/logs';
  static const String facesPrefix = '/faces';

  // ── Pagination defaults ────────────────────────────────────────────────
  static const int defaultPageSize = 50;

  // ── Endpoint builders ──────────────────────────────────────────────────

  /// `GET /media/?skip=&limit=&filter_type=`
  static String listMediaUrl({
    int skip = 0,
    int limit = defaultPageSize,
    String? filterType,
  }) {
    final base = '$baseUrl$mediaPrefix/?skip=$skip&limit=$limit';
    return filterType != null ? '$base&filter_type=$filterType' : base;
  }

  /// `GET /media/{filename}/thumbnail`
  static String thumbnailUrl(String filename) =>
      '$baseUrl$mediaPrefix/$filename/thumbnail';

  /// `GET /media/{filename}/full`
  static String fullUrl(String filename) =>
      '$baseUrl$mediaPrefix/$filename/full';

  /// `GET /media/{filename}/stream`
  static String streamUrl(String filename) =>
      '$baseUrl$mediaPrefix/$filename/stream';

  /// `GET /logs/?limit=`
  static String logsUrl({int limit = 100}) =>
      '$baseUrl$logsPrefix/?limit=$limit';

  // ── Faces endpoints ────────────────────────────────────────────────────

  /// `GET /faces/persons`
  static String get personsUrl => '$baseUrl${facesPrefix}/persons';

  /// `GET /faces/person/{id}`
  static String personImagesUrl(int personId) =>
      '$baseUrl${facesPrefix}/person/$personId';

  /// `PUT /faces/person/{id}/name`
  static String personNameUrl(int personId) =>
      '$baseUrl${facesPrefix}/person/$personId/name';

  /// Returns thumbnail URL for a given absolute file_path returned by the server.
  /// The server stores paths like `/data/camera/IMG_xxx.jpg`; we extract the
  /// filename and build a media thumbnail URL.
  static String faceImageThumbnailUrl(String filePath) {
    final filename = filePath.split('/').last.split(r'\').last;
    return thumbnailUrl(filename);
  }

  /// Full-resolution URL for a face source image.
  static String faceImageFullUrl(String filePath) {
    final filename = filePath.split('/').last.split(r'\').last;
    return fullUrl(filename);
  }
}
