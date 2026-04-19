/// Central place for all API base URLs and endpoint builders.
/// Change [baseUrl] to point to a different server.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.0.207:8000';
  static const String mediaPrefix = '/media';

  // ── Pagination defaults ────────────────────────────────────────────────
  static const int defaultPageSize = 50;

  // ── Endpoint builders ──────────────────────────────────────────────────

  /// `GET /media/?skip=&limit=`
  static String listMediaUrl({int skip = 0, int limit = defaultPageSize}) =>
      '$baseUrl$mediaPrefix/?skip=$skip&limit=$limit';

  /// `GET /media/{filename}/thumbnail`
  static String thumbnailUrl(String filename) =>
      '$baseUrl$mediaPrefix/$filename/thumbnail';

  /// `GET /media/{filename}/full`
  static String fullUrl(String filename) =>
      '$baseUrl$mediaPrefix/$filename/full';

  /// `GET /media/{filename}/stream`
  static String streamUrl(String filename) =>
      '$baseUrl$mediaPrefix/$filename/stream';
}
