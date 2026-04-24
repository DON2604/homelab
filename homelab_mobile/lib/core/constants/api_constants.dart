/// Central place for all API base URLs and endpoint builders.
/// Change [baseUrl] to point to a different server.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://hip-trim-dirt-duration.trycloudflare.com';
  static const String mediaPrefix = '/media';
  static const String logsPrefix = '/logs';

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
}
