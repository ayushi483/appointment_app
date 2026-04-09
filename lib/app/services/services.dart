import "package:shared_preferences/shared_preferences.dart";

class StorageService {
  static Future<Map<String, dynamic>> getLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'patientId':    prefs.getInt('patientId') ?? 0,
      'apiKey':       prefs.getString('apiKey') ?? '',
      'patientName':  prefs.getString('patientName') ?? '',
      'patientEmail': prefs.getString('patientEmail') ?? '',
      'patientPhone': prefs.getString('patientPhone') ?? '',
      'patientCode':  prefs.getString('patientCode') ?? '',
    };
  }

  static Future<void> saveLogin({
    required int    patientId,
    required String apiKey,
    String patientName  = '',
    String patientEmail = '',
    String patientPhone = '',
    String patientCode  = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('patientId',       patientId);
    await prefs.setString('apiKey',       apiKey);
    await prefs.setString('patientName',  patientName);
    await prefs.setString('patientEmail', patientEmail);
    await prefs.setString('patientPhone', patientPhone);
    await prefs.setString('patientCode',  patientCode);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}