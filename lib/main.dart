import 'package:flutter/material.dart';
import 'package:clinic_management/app/core/theme_notifier.dart';
import 'package:clinic_management/app/core/session.dart';
import 'package:clinic_management/app/routes/app_routes.dart';
import 'package:clinic_management/app/modules/chatbot/chatbot_widget.dart';

void main() {
  runApp(const ClinicApp());
}

class ClinicApp extends StatefulWidget {
  const ClinicApp({super.key});

  @override
  State<ClinicApp> createState() => _ClinicAppState();
}

class _ClinicAppState extends State<ClinicApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = AppRoutes.login;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Clinic Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2563EB)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF111827),
            useMaterial3: true,
          ),
          themeMode: themeMode,
          initialRoute: AppRoutes.login,
          onGenerateRoute: (settings) {
            // Track route changes so we know whether to show the chatbot
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() =>
                _currentRoute = settings.name ?? AppRoutes.login);
              }
            });
            return AppRoutes.generateRoute(settings);
          },
          // ── Global builder: wraps every screen in a Stack so the
          //    chatbot FAB floats above the bottom nav bar after login ──
          builder: (context, child) {
            final isAuthScreen = _currentRoute == AppRoutes.login ||
                _currentRoute == AppRoutes.register;
            final loggedIn = AppSession.patientId != 0;
            final showChatbot = !isAuthScreen && loggedIn;

            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (showChatbot)
                // SafeArea + bottom padding so the FAB sits just
                // above the bottom navigation bar (typically ~70px)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 72, // clears the bottom nav bar
                        left: 20,
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: const ClinicChatbotOverlay(),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}