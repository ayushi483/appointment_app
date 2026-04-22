import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clinic_management/app/core/session.dart';

class ViewAppointmentController {
  static const String _baseUrl = 'http://192.168.1.43:8093';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AppSession.apiKey != null)
      'Authorization': 'Bearer ${AppSession.apiKey!}',
  };

  Future<Map<String, dynamic>> fetchAppointments(String status) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v19/patient/appointments'),
        headers: _headers,
        body: jsonEncode({'patient_id': AppSession.patientId}),
      );

      debugPrint('fetchAppointments [$status] status: ${response.statusCode}');
      debugPrint('fetchAppointments body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List all = data['data']['appointments'] ?? [];

          debugPrint('Total appointments from API: ${all.length}');
          if (all.isNotEmpty) {
            debugPrint('Sample appointment keys: ${(all[0] as Map).keys.toList()}');
            debugPrint('Sample appointment: ${all[0]}');
          }

          // Status mapping — handles all possible API values
          final statusMap = {
            'confirmed': ['confirmed', 'draft'],
            'done':      ['done', 'completed'],
            'cancel':    ['cancel', 'cancelled', 'canceled'],
            'no_show':   ['no_show', 'no-show', 'noshow'],
          };

          final acceptedStatuses = statusMap[status] ?? [status];

          final filtered = all.where((a) {
            final s = (a['status'] ?? '').toString().toLowerCase();
            return acceptedStatuses.contains(s);
          }).toList();

          debugPrint('Filtered [$status]: ${filtered.length}');

          // Normalize field names so the view always gets consistent keys
          final normalized = filtered.map((a) {
            final map = Map<String, dynamic>.from(a);
            return {
              'appointment_id':       map['appointment_id'] ?? map['id'] ?? 0,
              'appointment_code':     map['appointment_code'] ?? map['name'] ?? '',
              'doctor_name':          map['doctor_name'] ?? map['doctor'] ?? '',
              'doctor_speciality':    map['doctor_speciality'] ?? map['speciality'] ?? map['speciality_name'] ?? '',
              'appointment_datetime': map['appointment_datetime'] ?? map['date'] ?? map['datetime'] ?? '',
              'status':               map['status'] ?? '',
              'notes':                map['notes'] ?? map['note'] ?? '',
              'patient_name':         map['patient_name'] ?? AppSession.patientName ?? '',
            };
          }).toList();

          return {'success': true, 'appointments': normalized};
        }
      }
      return {'success': false, 'appointments': []};
    } catch (e) {
      debugPrint('fetchAppointments error: $e');
      return {'success': false, 'appointments': []};
    }
  }

  Future<Map<String, dynamic>> fetchNoShowAppointments() async {
    return fetchAppointments('no_show');
  }

  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v19/patient/cancel_appointment'),
        headers: _headers,
        body: jsonEncode({'appointment_id': appointmentId}),
      );

      debugPrint('cancelAppointment status: ${response.statusCode}');
      debugPrint('cancelAppointment body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? '',
        };
      }
      return {'success': false, 'message': 'Server error ${response.statusCode}'};
    } catch (e) {
      debugPrint('cancelAppointment error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}