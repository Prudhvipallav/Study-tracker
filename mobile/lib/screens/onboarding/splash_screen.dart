import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [ThemeManager.primary, ThemeManager.background]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: ThemeManager.primary.withAlpha(102), blurRadius: 30, spreadRadius: 5)],
              ),
              child: const Center(child: Text('🎓', style: TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(colors: [ThemeManager.primary, ThemeManager.secondary]).createShader(rect),
              child: const Text('StudentTrack Pro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text('Study Smart. Track Everything.', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}
