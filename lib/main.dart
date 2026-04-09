import 'package:flutter/material.dart';
import 'package:clinic_management/app/routes/app_routes.dart';
import 'package:clinic_management/app/core/session.dart';
import 'package:clinic_management/app/services/services.dart';
import 'package:clinic_management/app/core/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final saved = await StorageService.getLogin();
    AppSession.restore(saved);
  } catch (e) {
    debugPrint('Session restore failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'HealthCare',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}