import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:homelab_mobile/core/constants/api_constants.dart';
import 'package:homelab_mobile/features/faces/domain/models/face_models.dart';

/// Data layer: fetches face cluster data from the FastAPI /faces/* endpoints.
class FacesRepository {
  const FacesRepository();

  /// `GET /faces/persons` — returns all person clusters with face counts.
  Future<List<FaceCluster>> getPersons() async {
    final response = await http
        .get(Uri.parse(ApiConstants.personsUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load persons: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => FaceCluster.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /faces/person/{id}` — returns all face images for a person cluster.
  Future<List<FaceImage>> getPersonImages(int personId) async {
    final response = await http
        .get(Uri.parse(ApiConstants.personImagesUrl(personId)))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load person images: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => FaceImage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `PUT /faces/person/{id}/name` — renames a person cluster.
  Future<void> renamePerson(int personId, String name) async {
    final response = await http
        .put(
          Uri.parse(ApiConstants.personNameUrl(personId)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to rename person: ${response.statusCode}');
    }
  }
}
