import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clinic_management/app/services/api_client.dart';
import 'package:clinic_management/app/core/session.dart';

class ProfileController extends ChangeNotifier {
  String name = '';
  String email = '';
  String phone = '';
  String gender = '';
  String dateOfBirth = '';
  String address = '';
  String patientCode = '';
  String? imageBase64;

  int patientId = 0;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  // ── Stats ─────────────────────────────────────
  bool statsLoading = false;
  int totalAppointments = 0;
  int completedAppointments = 0;
  int upcomingAppointments = 0;

  // ── Appointments List ─────────────────────────
  List<Map<String, dynamic>> appointments = [];

  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  String selectedGender = '';

  ProfileController() {
    name      = AppSession.patientName ?? '';
    phone     = AppSession.patientPhone ?? '';
    patientId = AppSession.patientId;
    phoneController.text = phone;
    init();
  }

  Future<void> init() async {
    await fetchPatientInfo();
  }

  // ── Fetch Profile ─────────────────────────────
  Future<void> fetchPatientInfo() async {
    try {
      isLoading     = true;
      errorMessage  = null;
      notifyListeners();

      patientId = AppSession.patientId;

      if (patientId == 0) {
        errorMessage = 'Session expired. Please login again.';
        isLoading    = false;
        notifyListeners();
        return;
      }

      final headers = await ApiClient.getHeaders();

      final res = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/v19/patient/info'),
        headers: headers,
        body: jsonEncode({'patient_id': patientId}),
      );

      final json = jsonDecode(res.body);

      if (json['success'] == true) {
        final data = json['data'];

        name        = data['name']          ?? '';
        email       = data['email']         ?? '';
        phone       = data['phone']         ?? '';
        gender      = data['gender']        ?? '';
        dateOfBirth = data['date_of_birth'] ?? '';
        address     = data['address']       ?? '';
        patientCode = data['patient_code']  ?? '';
        imageBase64 = data['image'];

        phoneController.text  = phone;
        dobController.text    = _formatDob(dateOfBirth);
        addressController.text = address;
        selectedGender        = gender;

        await _fetchStats();
      } else {
        errorMessage = json['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      errorMessage = 'Network error. Please check your connection.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Appointment Stats ───────────────────
  Future<void> _fetchStats() async {
    try {
      statsLoading = true;
      notifyListeners();

      final headers = await ApiClient.getHeaders();

      final res = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/v19/patient/appointments'),
        headers: headers,
        body: jsonEncode({'patient_id': patientId}),
      );

      final json = jsonDecode(res.body);

      if (json['success'] == true) {
        final data = json['data'];

        // ✅ Use direct counts from API
        totalAppointments     = data['total']     ?? 0;
        completedAppointments = data['completed'] ?? 0;
        upcomingAppointments  = data['upcoming']  ?? 0;

        // ✅ Store full appointments list
        appointments = List<Map<String, dynamic>>.from(
          data['appointments'] ?? [],
        );
      }
    } catch (_) {
      // Stats are non-critical, fail silently
    } finally {
      statsLoading = false;
      notifyListeners();
    }
  }

  // ── Update Profile ────────────────────────────
  Future<bool> updatePatient() async {
    try {
      isSaving = true;
      notifyListeners();

      if (patientId == 0) return false;

      final headers = await ApiClient.getHeaders();

      final body = {
        'patient_id':   patientId,
        'phone':        phoneController.text.trim(),
        'gender':       selectedGender,
        'address':      addressController.text.trim(),
        'date_of_birth': _parseDob(dobController.text),
      };

      final res = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/v19/patient/update'),
        headers: headers,
        body: jsonEncode(body),
      );

      final json = jsonDecode(res.body);

      if (json['success'] == true) {
        errorMessage = null;
        await fetchPatientInfo();
        return true;
      }

      return false;
    } catch (_) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────
  String _formatDob(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split('-');
    return parts.length == 3
        ? '${parts[2]}/${parts[1]}/${parts[0]}'
        : raw;
  }

  String _parseDob(String display) {
    if (display.isEmpty) return '';
    final parts = display.split('/');
    return parts.length == 3
        ? '${parts[2]}-${parts[1]}-${parts[0]}'
        : display;
  }

  String get avatarInitial =>
      name.isNotEmpty ? name[0].toUpperCase() : 'U';

  @override
  void dispose() {
    phoneController.dispose();
    dobController.dispose();
    addressController.dispose();
    super.dispose();
  }
}