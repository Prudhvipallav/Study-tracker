import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;

  static const _streamNames = {
    'engineering': '🔧 Engineering',
    'medical': '🩺 Medical',
    'law': '⚖️ Law',
    'competitive': '📖 Competitive',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await DbHelper.instance.fetchOne('SELECT * FROM profiles LIMIT 1');
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final stream = _profile?['stream'] as String? ?? 'engineering';
    final name = _profile?['name'] as String? ?? '';
    final avatar = _profile?['avatar'] as String? ?? '🎓';


    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: ThemeManager.primary.withOpacity(0.4))),
          child: Row(children: [
            Text(avatar, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(_streamNames[stream] ?? stream, style: TextStyle(color: ThemeManager.primary, fontSize: 13)),
              Text('🔒 Stream is permanently locked', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        SectionHeader(title: 'Notifications'),
        _tile('🔔 Daily Habit Reminder', 'Set a daily reminder time', () async {
          final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
          if (t != null) { await NotificationService.scheduleHabitReminder(t); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${t.format(context)}'), backgroundColor: ThemeManager.primary)); }
        }),
        _tile('💧 Water Reminder', 'Get reminded to stay hydrated', () async { await NotificationService.scheduleWaterReminder(2); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('💧 Water reminder sent!'), backgroundColor: ThemeManager.primary)); }),
        SectionHeader(title: 'Data'),
        _tile('🗑️ Clear All Data', 'Reset everthing — WARNING: Irreversible', () => _confirmReset(), isDanger: true),
        SectionHeader(title: 'About'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ThemeManager.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Text('🎓', style: TextStyle(fontSize: 28)), const SizedBox(width: 12), Text('StudentTrack Pro', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 16))]),
            const SizedBox(height: 8),
            Text('Mobile App v1.0.0', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
            Text('Companion app for StudentTrack Pro Desktop', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
            Text('100% offline · All data stored on device', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _tile(String title, String sub, VoidCallback onTap, {bool isDanger = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: isDanger ? ThemeManager.danger : ThemeManager.textColor, fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, color: ThemeManager.textSecondary, size: 14),
      onTap: onTap,
    );
  }

  void _confirmReset() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: ThemeManager.card,
      title: Text('⚠️ Clear All Data?', style: TextStyle(color: ThemeManager.danger)),
      content: Text('This will permanently delete ALL your data. This cannot be undone.', style: TextStyle(color: ThemeManager.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final db = await DbHelper.instance.database;
            for (final t in ['todos', 'habits', 'habit_logs', 'goals', 'milestones', 'subtasks', 'countdowns', 'pomodoro_sessions', 'notes', 'flashcard_decks', 'flashcards', 'attendance', 'attendance_logs', 'health_logs', 'xp_logs', 'badges', 'profiles', 'app_opens']) {
              await db.delete(t);
            }
            Navigator.pop(context);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.danger),
          child: const Text('Reset All'),
        ),
      ],
    ));
  }
}
