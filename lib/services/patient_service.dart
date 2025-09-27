import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class PatientService {
  final String _baseUrl = 'https://app.scribehealth.ai/api';
  final String _userId = 'user_123'; // TODO: Replace with actual user ID
  final String _authToken = 'your_auth_token_here'; // TODO: Replace with actual JWT token

  Future<List<Patient>> getPatients() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/patients?userId=$_userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching patients: $e');
    }
    return [];
  }

  Future<Patient?> addPatient(String name, {String? email, String? phone}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/add-patient-ext'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'userId': _userId,
          'name': name,
          'email': email,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Patient.fromJson(data);
      }
    } catch (e) {
      print('Error adding patient: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSessionsByPatient(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/fetch-session-by-patient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching sessions: $e');
    }
    return [];
  }
}