import 'package:flutter/material.dart';
import '../modules/login/view/login_view.dart';
import '../modules/registration/view/registration_view.dart';
import '../modules/appointment/view/appointment_view.dart';
import '../modules/doctor/view/doctor_view.dart';
import '../modules/booking/view/booking_view.dart';
import '../modules/view_appointment/view/view_appointment_view.dart';
import '../modules/specialityBYdoctor/view/specialityBydoctor.dart';
import '../modules/profile/view/profile_view.dart';
import '../modules/setting/view/setting_view.dart';
import 'package:clinic_management/app/core/session.dart'; // ← import AppSession

class AppRoutes {
  static const String login              = '/login';
  static const String register           = '/register';
  static const String home               = '/home';
  static const String doctors            = '/doctors';
  static const String booking            = '/booking';
  static const String viewAppointments   = '/view-appointments';
  static const String specialityDoctors  = '/speciality-doctors';
  static const String profile            = '/profile';
  static const String settings           = '/settings';
  static const String appointmentSearch  = '/appointment-search';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {

      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());

      case register:
        return MaterialPageRoute(builder: (_) => const RegistrationView());

      case home:
      // ── FIX: always prefer AppSession.patientName so the name
      //         never reverts to 'User' after the first build.
        return MaterialPageRoute(
          builder: (_) => AppointmentView(
            patientName: AppSession.patientName ?? 'User',
          ),
        );

      case doctors:
        return MaterialPageRoute(builder: (_) => const DoctorView());

      case booking:
        return MaterialPageRoute(builder: (_) => const BookingView());

      case viewAppointments:
        return MaterialPageRoute(builder: (_) => const ViewAppointmentView());

      case specialityDoctors:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SpecialityByDoctorView(),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileView());

      case settings:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SettingsView(
            // ── FIX: same pattern — AppSession first, args as fallback
            name:  AppSession.patientName  ?? args?['name']  ?? 'User',
            email: AppSession.patientEmail ?? args?['email'] ?? '',
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginView());
    }
  }
}