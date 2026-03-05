import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';

class StatusApi {
  static Future<Map<String, dynamic>> getStatus() async {
    final uri = Uri.parse('$baseUrl/api/status');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}
