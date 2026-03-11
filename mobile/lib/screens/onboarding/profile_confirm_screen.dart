import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_manager.dart';
import '../../providers/profile_provider.dart';
import '../main_shell.dart';

class ProfileConfirmScreen extends StatefulWidget {
  final String name;
  final String stream;
  const ProfileConfirmScreen({super.key, required this.name, required this.stream});
  @override
  State<ProfileConfirmScreen> createState() => _ProfileConfirmScreenState();
}

class _ProfileConfirmScreenState extends State<ProfileConfirmScreen> {
  String _avatar = '🎓';
  bool _saving = false;
  static const _avatars = ['🎓', '📚', '🔬', '⚖️', '💻', '🏆', '🎯', '🔭', '🌟', '🩺'];
  static const _streamIcons = {'engineering': '🔧', 'medical': '🩺', 'law': '⚖️', 'competitive': '📖'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            Text('Almost there! 🎉', style: TextStyle(color: ThemeManager.textColor, fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Choose your avatar', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 15)),
            const SizedBox(height: 32),
            // Avatar selector
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _avatars.map((a) {
                final sel = _avatar == a;
                return GestureDetector(
                  onTap: () => setState(() => _avatar = a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: sel ? ThemeManager.primary.withOpacity(0.2) : ThemeManager.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: sel ? ThemeManager.primary : ThemeManager.border, width: sel ? 2 : 1),
                    ),
                    child: Center(child: Text(a, style: const TextStyle(fontSize: 28))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Profile preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeManager.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeManager.primary.withOpacity(0.4), width: 2),
                boxShadow: [BoxShadow(color: ThemeManager.primary.withOpacity(0.15), blurRadius: 20)],
              ),
              child: Row(children: [
                Text(_avatar, style: const TextStyle(fontSize: 52)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.name, style: TextStyle(color: ThemeManager.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeManager.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_streamIcons[widget.stream]} ${widget.stream[0].toUpperCase()}${widget.stream.substring(1)}',
                        style: TextStyle(color: ThemeManager.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  Text('Level 1  ·  0 XP', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
                ])),
              ]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("Let's go! 🚀", style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<ProfileProvider>();
      await prov.createProfile(widget.name, widget.stream, _avatar);
      // createProfile already loads the theme — no need to call loadTheme again
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('Profile creation error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e'), backgroundColor: ThemeManager.danger),
        );
      }
    }
  }
}
