import 'package:clinic_management/app/core/session.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.1.43:8093'; // ✅ your Odoo server

  static Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppSession.apiKey}', // ✅ token from login
    };
  }
}