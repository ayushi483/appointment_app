import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/session.dart';
import '../../../services/services.dart';

class LoginController {
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading        = false;
  bool obscurePassword  = true;
  bool rememberMe       = false;

  static const String baseUrl = 'http://192.168.1.43:8093';

  String? validate() {
    final input    = emailController.text.trim();
    final password = passwordController.text.trim();
    if (input.isEmpty)    return 'Email or phone number is required';
    if (password.isEmpty) return 'Password is required';
    return null;
  }

  Future<Map<String, dynamic>> login() async {
    final error = validate();
    if (error != null) return {'success': false, 'message': error};

    final input   = emailController.text.trim();
    final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(input);

    try {
      final body = <String, dynamic>{
        'password': passwordController.text.trim(),
      };

      if (isPhone) {
        body['mobile'] = input;
      } else {
        body['email'] = input;
      }

      debugPrint('Login request body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v19/patient/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('Login status: ${response.statusCode}');
      debugPrint('Login response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final d = data['data'] as Map<String, dynamic>;

        // 1️⃣ Populate in-memory session
        AppSession.apiKey       = d['api_key'];
        AppSession.patientName  = d['name'] ?? 'User';
        AppSession.patientId    = d['patient_id'] is int
            ? d['patient_id']
            : int.tryParse(d['patient_id'].toString()) ?? 0;
        AppSession.patientPhone = d['phone'] ?? '';
        AppSession.patientEmail = d['email'] ?? '';
        AppSession.patientCode  = d['patient_code'] ?? '';

        debugPrint('Session saved — patientId: ${AppSession.patientId}, '
            'name: ${AppSession.patientName}, '
            'apiKey: ${AppSession.apiKey}');

        // 2️⃣ Persist ALL fields so they survive app restarts
        await StorageService.saveLogin(
          patientId:    AppSession.patientId,
          apiKey:       AppSession.apiKey!,
          patientName:  AppSession.patientName!,
          patientEmail: AppSession.patientEmail!,
          patientPhone: AppSession.patientPhone!,
          patientCode:  AppSession.patientCode!,
        );

        return {
          'success':      true,
          'name':         AppSession.patientName,
          'patient_id':   AppSession.patientId,
          'email':        AppSession.patientEmail,
          'phone':        AppSession.patientPhone,
          'patient_code': AppSession.patientCode,
          'age':          d['age'],
          'gender':       d['gender'] ?? '',
          'user_id':      d['user_id'],
          'api_key':      AppSession.apiKey,
        };
      }

      final err = data['error'] as Map<String, dynamic>?;
      return {
        'success': false,
        'message': err?['message'] ?? 'Invalid credentials',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Connection error. Please try again.'};
    }
  }

  void togglePasswordVisibility(void Function(void Function()) setState) {
    setState(() => obscurePassword = !obscurePassword);
  }

  void toggleRememberMe(bool? value, void Function(void Function()) setState) {
    setState(() => rememberMe = value ?? false);
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}