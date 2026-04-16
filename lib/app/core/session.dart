class AppSession {
  static String? apiKey;
  static String? patientName;
  static int     patientId   = 0;
  static String? patientEmail;
  static String? patientPhone;
  static String? patientCode;
  static String? sessionToken;

  /// Call this on app startup to restore session from SharedPreferences data.
  static void restore(Map<String, dynamic> saved) {
    if (saved['apiKey'] != '' && saved['patientId'] != 0) {
      apiKey       = saved['apiKey'];
      patientId    = saved['patientId'];
      patientName  = saved['patientName'];
      patientEmail = saved['patientEmail'];
      patientPhone = saved['patientPhone'];
      patientCode  = saved['patientCode'];
      sessionToken = saved['sessionToken'];
    }
  }

  static void clear() {
    apiKey       = null;
    patientName  = null;
    patientId    = 0;
    patientEmail = null;
    patientPhone = null;
    patientCode  = null;
    sessionToken = null;
  }
}