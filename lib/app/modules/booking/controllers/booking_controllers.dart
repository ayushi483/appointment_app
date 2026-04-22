import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/session.dart';

class BookingController {
  static const String baseUrl = 'http://192.168.1.43:8093';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AppSession.apiKey}',
  };

  // ── Fetch Doctors ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v19/get_doctor_list'),
        headers: _headers,
      );

      debugPrint('Fetch doctors status: ${response.statusCode}');
      debugPrint('Fetch doctors response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final d = data['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'doctors': (d['doctors'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        };
      }

      final err = data['error'] as Map<String, dynamic>?;
      return {
        'success': false,
        'message': err?['message'] ?? 'Failed to load doctors',
      };
    } catch (e) {
      debugPrint('Fetch doctors error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Check Availability ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkAvailability({
    required int doctorId,
    required String appointmentDatetime,
  }) async {
    try {
      final body = {
        'doctor_id': doctorId,
        'appointment_datetime': appointmentDatetime,
      };

      debugPrint('Check availability body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v19/appointment/check_availability'),
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('Check availability status: ${response.statusCode}');
      debugPrint('Check availability response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'] as Map<String, dynamic>,
        };
      }

      final err = data['error'] as Map<String, dynamic>?;
      return {
        'success': false,
        'message': err?['message'] ?? 'Availability check failed',
      };
    } catch (e) {
      debugPrint('Check availability error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }

  // ── Book Appointment ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> bookAppointment({
    required int doctorId,
    required int patientId,
    required String appointmentDatetime,
    required String notes,
  }) async {
    try {
      final body = {
        'doctor_id': doctorId,
        'patient_id': patientId,
        'appointment_datetime': appointmentDatetime,
        'notes': notes,
      };

      debugPrint('Book appointment body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v19/appointment/book'),
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('Book appointment status: ${response.statusCode}');
      debugPrint('Book appointment response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return {
          'success': true,
          'data': data['data'] as Map<String, dynamic>,
        };
      }

      final err = data['error'] as Map<String, dynamic>?;
      return {
        'success': false,
        'message': err?['message'] ?? 'Booking failed',
      };
    } catch (e) {
      debugPrint('Book appointment error: $e');
      return {'success': false, 'message': 'Connection error.'};
    }
  }
}