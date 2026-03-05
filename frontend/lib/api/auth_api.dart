import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';

class AuthApi {
  // Student Login
  static Future<Map<String, dynamic>> studentLogin({
    required String registrationNumber,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/students/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'registrationNumber': registrationNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final data = json.decode(response.body);
        final msg = data['error'] ?? data['message'];
        throw Exception(msg);
      } on FormatException {
        throw Exception('Invalid registration number or password');
      }
    }
  }

  // Student Change Password
static Future<Map<String, dynamic>> changeStudentPassword({
  required String registrationNumber,
  required String oldPassword,
  required String newPassword,
}) async {
  final uri = Uri.parse('$baseUrl/api/students/change-password');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'registrationNumber': registrationNumber,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    // ✅ Default clean fallback
    String friendlyMessage =
        'Could not change password. Please try again.';

    try {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        final rawMsg =
            (decoded['error'] ?? decoded['message'])?.toString();

        if (rawMsg != null && rawMsg.isNotEmpty) {
          // ✅ Map known backend errors to clean UI text
          if (rawMsg == 'Invalid registration number or password' ||
              rawMsg == 'Current password is incorrect') {
            friendlyMessage = 'Current password is incorrect.';
          } else if (rawMsg == 'Internal server error') {
            friendlyMessage =
                'Something went wrong on the server. Please try again later.';
          } else {
            // ✅ Any other backend message → show as-is
            friendlyMessage = rawMsg;
          }
        }
      }
    } catch (_) {
      // ✅ If JSON parsing fails, keep the default friendly message
    }

    throw Exception(friendlyMessage);
  }
}

}
