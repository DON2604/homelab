import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:homelab_mobile/core/constants/api_constants.dart';
import 'package:homelab_mobile/features/gallery/domain/models/media_item.dart';

/// Custom exceptions for cleaner error handling upstream.
class MediaFetchException implements Exception {
  const MediaFetchException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'MediaFetchException($statusCode): $message';
}

/// Handles all raw HTTP calls to the `/media` endpoints.
class MediaRemoteDataSource {
  MediaRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Calls `GET /media/?skip=&limit=&filter_type=` and parses the response.
  Future<MediaPage> fetchMedia({
    int skip = 0,
    int limit = 50,
    String? filterType,
  }) async {
    final url = ApiConstants.listMediaUrl(
      skip: skip,
      limit: limit,
      filterType: filterType,
    );
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return MediaPage.fromJson(json);
      }

      throw MediaFetchException(
        'Server returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const MediaFetchException(
        'Cannot reach server. Check your network or server IP.',
      );
    } on MediaFetchException {
      rethrow;
    } catch (e) {
      throw MediaFetchException('Unexpected error: $e');
    }
  }
}
