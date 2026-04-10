import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/session.dart';

class DoctorController {
  static const String baseUrl = 'http://10.0.2.2:8093';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AppSession.apiKey != null)
      'Authorization': 'Bearer ${AppSession.apiKey!}',
  };

  Future<Map<String, dynamic>> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v19/get_doctor_list'),
        headers: _headers,
      );

      debugPrint('Doctors status: ${response.statusCode}');
      debugPrint('Doctors response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final d = data['data'] as Map<String, dynamic>;
          return {
            'success': true,
            'doctors': (d['doctors'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList(),
          };
        } else {
          final err = data['error'] as Map<String, dynamic>?;
          return {
            'success': false,
            'message': err?['message'] ?? 'Failed to load doctors'
          };
        }
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}'
      };
    } catch (e) {
      debugPrint('Fetch doctors error: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> fetchSpecialities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v19/get_speciality_list'),
        headers: _headers,
      );

      debugPrint('Specialities status: ${response.statusCode}');
      debugPrint('Specialities response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final d = data['data'] as Map<String, dynamic>;
          return {
            'success': true,
            'specialities': (d['speciality'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList(),
          };
        }
      }
      return {'success': false, 'message': 'Failed to load specialities'};
    } catch (e) {
      debugPrint('Fetch specialities error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }
}