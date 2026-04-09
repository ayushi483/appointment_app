import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/session.dart';

// ─── Speciality Model ─────────────────────────────────────────────────────────

class SpecialityModel {
  final int id;
  final String name;
  final String description;
  final bool active;
  final String? imageBase64;

  SpecialityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.imageBase64,
  });

  factory SpecialityModel.fromJson(Map<String, dynamic> json) {
    return SpecialityModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? true,
      imageBase64: json['image'],
    );
  }
}

// ─── Doctor Model ─────────────────────────────────────────────────────────────

class DoctorSearchModel {
  final int id;
  final String name;
  final String? speciality;
  final int? specialityId;
  final String? phone;
  final String? email;
  final double fees;
  final String? imageBase64;
  final bool available;
  final int totalAppointment;

  DoctorSearchModel({
    required this.id,
    required this.name,
    this.speciality,
    this.specialityId,
    this.phone,
    this.email,
    required this.fees,
    this.imageBase64,
    required this.available,
    this.totalAppointment = 0,
  });

  factory DoctorSearchModel.fromJson(Map<String, dynamic> json) {
    return DoctorSearchModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      speciality: json['speciality'] ?? json['speciality_name'],
      specialityId: json['speciality_id'],
      phone: json['phone'],
      email: json['email'],
      fees: (json['fees'] ?? 0).toDouble(),
      imageBase64: json['image'] ?? json['image_1024'],
      available: json['available'] ?? json['is_available'] ?? false,
      totalAppointment: json['total_appointment'] ?? 0,
    );
  }
}

// ─── Appointment Model ────────────────────────────────────────────────────────

class AppointmentModel {
  final int appointmentId;
  final String appointmentCode;
  final String doctorName;
  final String? doctorSpeciality;
  final String patientName;
  final String appointmentDatetime;
  final String status;
  final String notes;

  AppointmentModel({
    required this.appointmentId,
    required this.appointmentCode,
    required this.doctorName,
    this.doctorSpeciality,
    required this.patientName,
    required this.appointmentDatetime,
    required this.status,
    required this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Odoo stores the sequence in 'appointment_code' OR 'name' field
    final code =
    (json['appointment_code'] ?? json['name'] ?? '').toString().trim();

    return AppointmentModel(
      appointmentId: json['appointment_id'] ?? json['id'] ?? 0,
      appointmentCode: code,
      doctorName: json['doctor_name'] ?? json['doctor'] ?? '',
      doctorSpeciality: json['doctor_speciality'] ?? json['speciality'],
      patientName: json['patient_name'] ?? AppSession.patientName ?? '',
      appointmentDatetime: json['appointment_datetime'] ?? json['date'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(appointmentDatetime);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return appointmentDatetime;
    }
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(appointmentDatetime).toLocal();
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class AppointmentController extends ChangeNotifier {
  static const String _baseUrl = 'http://10.0.2.2:8093';

  List<SpecialityModel> specialities = [];
  bool loadingSpecialities = false;
  String? specialityError;

  AppointmentModel? upcomingAppointment;
  bool loadingAppointment = false;
  String? appointmentError;

  List<DoctorSearchModel> doctorResults = [];
  List<AppointmentModel> appointmentResults = [];
  bool isSearching = false;
  String searchQuery = '';
  String? searchError;

  List<DoctorSearchModel> get searchResults => doctorResults;

  AppointmentController() {
    fetchSpecialities();
    fetchUpcomingAppointment();
  }

  // POST headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AppSession.apiKey != null)
      'Authorization': 'Bearer ${AppSession.apiKey!}',
  };

  // GET headers
  Map<String, String> get _getHeaders => {
    if (AppSession.apiKey != null)
      'Authorization': 'Bearer ${AppSession.apiKey!}',
  };

  // ── Fetch Specialities ──────────────────────────────────────────────────────

  Future<void> fetchSpecialities() async {
    loadingSpecialities = true;
    specialityError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/v19/get_speciality_list');
      final response = await http.get(uri, headers: _headers);
      debugPrint('Speciality status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data is Map ? (data['data'] ?? data) : data;
        final List list = raw['speciality'] ?? [];
        specialities = list.map((e) => SpecialityModel.fromJson(e)).toList();
        debugPrint('Loaded ${specialities.length} specialities');
      } else {
        specialityError = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Speciality fetch error: $e');
      specialityError = e.toString();
    } finally {
      loadingSpecialities = false;
      notifyListeners();
    }
  }

  // ── Fetch Upcoming Appointment ──────────────────────────────────────────────

  Future<void> fetchUpcomingAppointment() async {
    loadingAppointment = true;
    appointmentError = null;
    notifyListeners();

    try {
      final patientId = AppSession.patientId;
      if (patientId == 0) {
        upcomingAppointment = null;
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v19/patient/appointments'),
        headers: _headers,
        body: jsonEncode({'patient_id': patientId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final d = data['data'] as Map<String, dynamic>;
          final List list = d['appointments'] ?? [];
          final now = DateTime.now();

          final filtered = list
              .map((e) =>
              AppointmentModel.fromJson(e as Map<String, dynamic>))
              .where((a) {
            final s = a.status;
            if (s != 'confirmed' && s != 'draft') return false;
            try {
              final dt = DateTime.parse(a.appointmentDatetime).toLocal();
              return dt.isAfter(now);
            } catch (_) {
              return false;
            }
          }).toList();

          filtered.sort((a, b) => DateTime.parse(a.appointmentDatetime)
              .compareTo(DateTime.parse(b.appointmentDatetime)));

          upcomingAppointment =
          filtered.isNotEmpty ? filtered.first : null;
        } else {
          upcomingAppointment = null;
        }
      } else {
        appointmentError = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Upcoming appointment fetch error: $e');
      appointmentError = e.toString();
    } finally {
      loadingAppointment = false;
      notifyListeners();
    }
  }

  // ── Appointment code detector ───────────────────────────────────────────────
  // Matches: APP0011, app0011, APP 0011, APT/2025/0001, 0011 (pure digits)
  bool _looksLikeAppointmentCode(String input) {
    final upper = input.toUpperCase().trim();
    if (upper.startsWith('APP')) return true;   // ← your format APP0011
    if (upper.startsWith('APT')) return true;   // ← slash format APT/...
    if (upper.contains('/')) return true;
    if (RegExp(r'^\d+$').hasMatch(upper)) return true; // pure digits
    return false;
  }

  // ── Unified Search ──────────────────────────────────────────────────────────

  Future<void> searchDoctors(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    setState(() {
      isSearching = true;
      searchQuery = query;
      searchError = null;
      doctorResults = [];
      appointmentResults = [];
    });

    try {
      final trimmed = query.trim();

      // ── 1. Appointment code search ──────────────────────────────────────
      if (_looksLikeAppointmentCode(trimmed)) {
        await _searchByAppointmentCode(trimmed);
        return;
      }

      // ── 2. Speciality name match ────────────────────────────────────────
      final matchingSpeciality = specialities.firstWhere(
            (s) => s.name.toLowerCase().contains(trimmed.toLowerCase()),
        orElse: () =>
            SpecialityModel(id: 0, name: '', description: '', active: false),
      );

      if (matchingSpeciality.id != 0) {
        final doctors = await getDoctorsBySpeciality(matchingSpeciality.id);
        setState(() {
          doctorResults = doctors;
          if (doctorResults.isEmpty) {
            searchError =
            'No doctors found for "${matchingSpeciality.name}"';
          }
        });
        return;
      }

      // ── 3. Doctor name search ───────────────────────────────────────────
      final allDoctors = await getAllDoctors();
      final filtered = allDoctors
          .where(
              (d) => d.name.toLowerCase().contains(trimmed.toLowerCase()))
          .toList();

      setState(() {
        doctorResults = filtered;
        if (doctorResults.isEmpty) {
          searchError = 'No results found for "$trimmed"';
        }
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => searchError = 'Error: $e');
    } finally {
      setState(() => isSearching = false);
    }
  }

  // ── Search by appointment code ──────────────────────────────────────────────

  Future<void> _searchByAppointmentCode(String code) async {
    debugPrint('=== Searching by code: "$code" ===');

    // ── Strategy 1: dedicated endpoint ─────────────────────────────────────
    try {
      final uri =
      Uri.parse('$_baseUrl/api/v19/appointments/search_by_code')
          .replace(queryParameters: {
        'code': code,
        'patient_id': AppSession.patientId.toString(),
      });

      final response = await http.get(uri, headers: _getHeaders);
      debugPrint('search_by_code → ${response.statusCode}');
      debugPrint('search_by_code body → ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List raw = data['data']['appointments'] ?? [];
          final list = raw
              .map((e) =>
              AppointmentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          debugPrint('Strategy 1 found ${list.length} result(s)');
          setState(() {
            appointmentResults = list;
            if (appointmentResults.isEmpty) {
              searchError = 'No appointment found with code "$code"';
            }
          });
          return; // ✅ success
        }
      }
      debugPrint(
          'Strategy 1 failed (${response.statusCode}) → trying Strategy 2');
    } catch (e) {
      debugPrint('Strategy 1 exception: $e → trying Strategy 2');
    }

    // ── Strategy 2: fetch all patient appointments, filter client-side ──────
    debugPrint('=== Strategy 2: client-side filter ===');
    try {
      final patientId = AppSession.patientId;
      debugPrint('patientId: $patientId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v19/patient/appointments'),
        headers: _headers,
        body: jsonEncode({'patient_id': patientId}),
      );

      debugPrint('patient/appointments → ${response.statusCode}');
      debugPrint('patient/appointments body → ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List allAppts = data['data']['appointments'] ?? [];
          debugPrint('Total appointments: ${allAppts.length}');

          // Log raw fields so we can verify field names
          if (allAppts.isNotEmpty) {
            final sample = allAppts[0] as Map<String, dynamic>;
            debugPrint('Keys: ${sample.keys.toList()}');
            debugPrint('appointment_code: ${sample['appointment_code']}');
            debugPrint('name: ${sample['name']}');
          }

          final list = allAppts
              .map((e) =>
              AppointmentModel.fromJson(e as Map<String, dynamic>))
              .toList();

          // Log every parsed code to verify mapping
          for (final a in list) {
            debugPrint(
                'Parsed → id:${a.appointmentId}  code:"${a.appointmentCode}"');
          }

          // Case-insensitive partial match — APP0011, app0011, 0011 all work
          final matched = list
              .where((a) =>
          a.appointmentCode.isNotEmpty &&
              a.appointmentCode
                  .toLowerCase()
                  .contains(code.toLowerCase()))
              .toList();

          debugPrint('Matched: ${matched.length}');

          setState(() {
            appointmentResults = matched;
            if (appointmentResults.isEmpty) {
              searchError = 'No appointment found with code "$code"';
            }
          });
          return;
        }
      }

      setState(() =>
      searchError = 'Could not fetch appointments. Please try again.');
    } catch (e) {
      debugPrint('Strategy 2 error: $e');
      setState(() => searchError = 'Error: $e');
    }
  }

  // ── Get Doctors by Speciality ───────────────────────────────────────────────

  Future<List<DoctorSearchModel>> getDoctorsBySpeciality(
      int specialityId) async {
    try {
      final uri =
      Uri.parse('$_baseUrl/api/v19/get_doctors_by_speciality')
          .replace(queryParameters: {
        'speciality_id': specialityId.toString()
      });

      final response = await http.get(uri, headers: _headers);
      debugPrint('getDoctorsBySpeciality status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final doctorsRaw = _extractDoctors(data);
        if (doctorsRaw != null && doctorsRaw.isNotEmpty) {
          return doctorsRaw
              .map((e) =>
              DoctorSearchModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getDoctorsBySpeciality error: $e — falling back');
    }

    try {
      final allDoctors = await getAllDoctors();
      return allDoctors
          .where((d) => d.specialityId == specialityId)
          .toList();
    } catch (e) {
      debugPrint('Fallback failed: $e');
      return [];
    }
  }

  // ── Get All Doctors ─────────────────────────────────────────────────────────

  Future<List<DoctorSearchModel>> getAllDoctors() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v19/get_doctor_list');
      final response = await http.get(uri, headers: _headers);
      debugPrint('getAllDoctors status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final doctorsRaw = _extractDoctors(data);
        if (doctorsRaw != null) {
          return doctorsRaw
              .map((e) =>
              DoctorSearchModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('getAllDoctors error: $e');
      return [];
    }
  }

  List<dynamic>? _extractDoctors(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['success'] == true) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner['doctors'] as List?;
    }
    if (data['result'] is Map<String, dynamic>) {
      final result = data['result'] as Map<String, dynamic>;
      final inner = result['data'];
      if (inner is Map<String, dynamic>) return inner['doctors'] as List?;
      return result['doctors'] as List?;
    }
    if (data['data'] is Map<String, dynamic>) {
      return (data['data'] as Map<String, dynamic>)['doctors'] as List?;
    }
    if (data['doctors'] is List) return data['doctors'] as List;
    return null;
  }

  void clearSearch() {
    doctorResults = [];
    appointmentResults = [];
    searchQuery = '';
    searchError = null;
    isSearching = false;
    notifyListeners();
  }

  bool get hasResults =>
      doctorResults.isNotEmpty || appointmentResults.isNotEmpty;

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}