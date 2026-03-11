import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/profile_provider.dart';
import 'services/notification_service.dart';
import 'services/quote_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('>>> APP START');

  // Don't await notification init — run it in the background
  // This is the #1 cause of startup hangs
  NotificationService.initialize().timeout(
    const Duration(seconds: 3),
    onTimeout: () => debugPrint('>>> NotificationService timed out (OK)'),
  ).catchError((e) => debugPrint('>>> NotificationService error (OK): $e'));

  // Load quotes in the background too
  QuoteService.load().timeout(
    const Duration(seconds: 2),
    onTimeout: () => debugPrint('>>> QuoteService timed out (OK)'),
  ).catchError((e) => debugPrint('>>> QuoteService error (OK): $e'));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  debugPrint('>>> Running app');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const StudentTrackApp(),
    ),
  );
}

class StudentTrackApp extends StatelessWidget {
  const StudentTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProv, _) {
        debugPrint('>>> Consumer rebuild: loading=${profileProv.loading} hasProfile=${profileProv.hasProfile}');
        return MaterialApp(
          title: 'StudentTrack Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: profileProv.loading
              ? const _Loader()
              : profileProv.hasProfile
                  ? const MainShell()
                  : const SplashScreen(),
        );
      },
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: ThemeManager.primary),
            const SizedBox(height: 16),
            Text('Loading…', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
