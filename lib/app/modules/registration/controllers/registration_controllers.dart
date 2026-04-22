import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/session.dart';

class RegistrationController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool agreedToTerms = false;
  String selectedGender = 'male';

  static const String baseUrl = 'http://192.168.1.43:8093';

  String? validate() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (name.isEmpty) return 'Full name is required';
    if (email.isEmpty) return 'Email is required';
    if (mobile.isEmpty) return 'Phone number is required';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (password != confirm) return 'Passwords do not match';
    if (!agreedToTerms) return 'Please agree to Terms of Service';
    return null;
  }

  Future<Map<String, dynamic>> register() async {
    final error = validate();
    if (error != null) return {'success': false, 'message': error};

    try {
      final requestBody = {
        'name': nameController.text.trim(),
        'mobile': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'gender': selectedGender,
        'age_years': 25,
      };

      debugPrint('Register request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v19/patient/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Register status: ${response.statusCode}');
      debugPrint('Register response: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final d = data['data'] as Map<String, dynamic>;

        // Save to session
        AppSession.apiKey = d['api_key'];
        AppSession.patientName = d['name'] ?? nameController.text.trim();
        AppSession.patientId = d['patient_id'];
        AppSession.patientPhone = d['phone'];

        return {
          'success': true,
          'name': d['name'] ?? nameController.text.trim(),
          'patient_id': d['patient_id'],
          'email': d['email'],
          'phone': d['phone'],
          'patient_code': d['patient_code'],
          'age': d['age'],
          'gender': d['gender'],
          'user_id': d['user_id'],
          'api_key': d['api_key'],
        };
      }

      final err = data['error'] as Map<String, dynamic>?;
      return {
        'success': false,
        'message': err?['message'] ?? 'Registration failed',
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {'success': false, 'message': 'Connection error. Please try again.'};
    }
  }

  void togglePasswordVisibility(void Function(void Function()) setState) {
    setState(() => obscurePassword = !obscurePassword);
  }

  void toggleConfirmVisibility(void Function(void Function()) setState) {
    setState(() => obscureConfirm = !obscureConfirm);
  }

  void toggleTerms(bool? value, void Function(void Function()) setState) {
    setState(() => agreedToTerms = value ?? false);
  }

  void setGender(String gender, void Function(void Function()) setState) {
    setState(() => selectedGender = gender);
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}