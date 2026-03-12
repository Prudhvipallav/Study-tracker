import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import 'profile_confirm_screen.dart';

class StreamSelectScreen extends StatefulWidget {
  final String name;
  const StreamSelectScreen({super.key, required this.name});
  @override
  State<StreamSelectScreen> createState() => _StreamSelectScreenState();
}

class _StreamSelectScreenState extends State<StreamSelectScreen> {
  String? _selected;

  static const _streams = [
    {'key': 'engineering', 'icon': '🔧', 'name': 'Engineering', 'sub': 'BTech / BE', 'color': '1E90FF'},
    {'key': 'medical',     'icon': '🩺', 'name': 'Medical',     'sub': 'MBBS / BDS', 'color': '00C896'},
    {'key': 'law',         'icon': '⚖️', 'name': 'Law',         'sub': 'LLB',        'color': 'C0392B'},
    {'key': 'competitive', 'icon': '📖', 'name': 'Competitive', 'sub': 'UPSC/JEE/NEET', 'color': '9B59B6'},
  ];

  Color _hex(String hex) => Color(int.parse('FF$hex', radix: 16));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 20),
            Text('Choose Your Path', style: TextStyle(color: ThemeManager.textColor, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Text('⚠️ This choice is permanent and cannot be changed',
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: _streams.map((s) {
                  final isSelected = _selected == s['key'];
                  final col = _hex(s['color']!);
                  return GestureDetector(
                    onTap: () => setState(() => _selected = s['key']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [col.withAlpha(isSelected ? 77 : 26), ThemeManager.card],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? col : ThemeManager.border, width: isSelected ? 2.5 : 1),
                        boxShadow: isSelected ? [BoxShadow(color: col.withAlpha(77), blurRadius: 16)] : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(s['icon']!, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 10),
                          Text(s['name']!, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(s['sub']!, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _selected != null ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected != null ? _confirm : null,
                  child: const Text('Confirm Selection', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _confirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeManager.card,
        title: Text('Are you sure?', style: TextStyle(color: ThemeManager.textColor)),
        content: Text('You cannot change your stream later. This is permanent.', style: TextStyle(color: ThemeManager.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProfileConfirmScreen(name: widget.name, stream: _selected!),
                transitionsBuilder: (_, anim, __, child) =>
                    SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim), child: child),
              ));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
