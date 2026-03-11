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
  await NotificationService.initialize();
  await QuoteService.load().catchError((_) {}); // graceful
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
        child: CircularProgressIndicator(color: ThemeManager.primary),
      ),
    );
  }
}
