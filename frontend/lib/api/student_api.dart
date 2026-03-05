import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class StudentApi {
  static Future<int> getStudentCount() async {
    final response = await http.get(Uri.parse('$baseUrl/api/students'));

    if (response.statusCode == 200) {
      final List students = jsonDecode(response.body);
      return students.length;
    } else {
      throw Exception('Failed to load students');
    }
  }

  static Future<Map<String, int>> getStudentStatusCounts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/students'));

    if (response.statusCode == 200) {
      final List students = jsonDecode(response.body);

      int active = 0;
      int blocked = 0;

      for (var s in students) {
        if (s['status'] == 'blocked') blocked++;
        if (s['status'] == 'active') active++;
      }

      return {'active': active, 'blocked': blocked};
    } else {
      throw Exception('Failed to load students');
    }
  }

  static Future<bool> addStudent({
    required String name,
    required String regNo,
    required String department,
    required String semester,
    required String batch,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/students'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "registrationNumber": regNo.toUpperCase(),
        "department": department,
        "semester": semester,
        "batch": batch,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<List<dynamic>> getAllStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/api/students'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load students");
    }
  }

  static Future<bool> deleteStudent(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/students/$id'));

    return response.statusCode == 200;
  }

  static Future<bool> updateStudent({
    required int id,
    required String name,
    required String registrationNumber,
    required String department,
    required String semester,
    required String batch,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/students/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "registrationNumber": registrationNumber,
          "department": department,
          "semester": semester,
          "batch": batch,
          "status": status,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Update student error: $e");
      return false;
    }
  }
}
