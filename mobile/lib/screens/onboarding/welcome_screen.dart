import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import 'stream_select_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameCtrl = TextEditingController();
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() => _showButton = _nameCtrl.text.trim().length >= 2));
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👋 What\'s your name?',
                  style: TextStyle(color: ThemeManager.textColor, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('We\'ll use this to personalise your experience.',
                  style: TextStyle(color: ThemeManager.textSecondary, fontSize: 15)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(color: ThemeManager.textColor, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter your name…',
                  prefixIcon: Icon(Icons.person_outline, color: ThemeManager.textSecondary),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _goNext(),
              ),
              const SizedBox(height: 40),
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showButton ? _goNext : null,
                    child: const Text('Continue →', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goNext() {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => StreamSelectScreen(name: name),
      transitionsBuilder: (_, anim, __, child) =>
          SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim), child: child),
    ));
  }
}
