import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:homelab_mobile/core/constants/api_constants.dart';

final logsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final url = ApiConstants.logsUrl(limit: 100);
  final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final logs = json['logs'] as List<dynamic>? ?? [];
    return logs.map((e) => e.toString()).toList();
  } else {
    throw Exception('Failed to load logs: ${response.statusCode}');
  }
});
