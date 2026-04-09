import 'package:clinic_management/app/core/session.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8093'; // ✅ your Odoo server

  static Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppSession.apiKey}', // ✅ token from login
    };
  }
}