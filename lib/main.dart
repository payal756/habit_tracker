import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mahadev/core/theme/app_theme.dart';
import 'package:mahadev/presentation/screens/splash_screen.dart';
import 'package:mahadev/presentation/screens/auth/login_screen.dart';
import 'package:mahadev/presentation/screens/auth/register_screen.dart';
import 'package:mahadev/presentation/screens/auth/onboarding_screen.dart';
import 'package:mahadev/presentation/screens/home_screen.dart';
import 'package:mahadev/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Request notification permission for Android 13+
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Request exact alarm permission for Android 12+
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }

  // Initialize notifications
  await NotificationService.initialize();

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '21-Day Habit Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterBasicInfoScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
