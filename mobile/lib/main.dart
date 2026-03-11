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

  // Wrap all pre-launch work in try/catch so the app ALWAYS starts
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NotificationService init failed (non-fatal): $e');
  }

  try {
    await QuoteService.load();
  } catch (e) {
    debugPrint('QuoteService load failed (non-fatal): $e');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
