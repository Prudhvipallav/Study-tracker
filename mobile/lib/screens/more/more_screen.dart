import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';
import '../health/health_screen.dart';
import '../attendance/attendance_screen.dart';
import '../countdown/countdown_screen.dart';
import '../goals/goals_screen.dart';
import '../flashcards/flashcards_screen.dart';
import 'badges_screen.dart';
import 'stats_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'sync_screen.dart';


class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem('🃏', 'Flashcards', 'Study with spaced repetition', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardsScreen()))),
      _MoreItem('⏰', 'Countdowns', 'Track exam dates', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CountdownScreen()))),
      _MoreItem('🎯', 'Goals', 'View goals & milestones', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()))),
      _MoreItem('❤️', 'Health', 'Sleep, water, mood, exercise', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen()))),
      _MoreItem('📊', 'Attendance', 'Track your class attendance', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()))),
      _MoreItem('📝', 'Notes', 'Quick notes & ideas', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()))),
      _MoreItem('📈', 'Stats', 'Your performance overview', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()))),
      _MoreItem('🏅', 'Badges', 'Achievements unlocked', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen()))),
      _MoreItem('⚙️', 'Settings', 'Notifications & preferences', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      _MoreItem('🔄', 'Sync', 'Sync with desktop PC', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncScreen()))),
    ];


    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('More')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DbHelper.instance.fetchOne('SELECT * FROM profiles LIMIT 1'),
        builder: (_, snap) {
          final profile = snap.data;
          final xp = (profile?['xp'] as int?) ?? 0;
          final level = (profile?['level'] as int?) ?? 1;
          final name = profile?['name'] as String? ?? '';
          final avatar = profile?['avatar'] as String? ?? '🎓';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeManager.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ThemeManager.primary.withAlpha(102), width: 2),
                  boxShadow: [BoxShadow(color: ThemeManager.primary.withAlpha(31), blurRadius: 20)],
                ),
                child: Column(children: [
                  Row(children: [
                    Text(avatar, style: const TextStyle(fontSize: 44)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      if (profile?['stream'] != null) StreamBadge(stream: profile!['stream'] as String),
                      Text('Level $level  ·  $xp XP', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  XpBarWidget(xp: xp, level: level),
                ]),
              ),
              const SizedBox(height: 20),
              // Grid of more items
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: items.map((item) => GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeManager.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ThemeManager.border),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(item.icon, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(item.label, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(item.sub, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10), textAlign: TextAlign.center),
                    ]),
                  ),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoreItem {
  final String icon, label, sub;
  final VoidCallback onTap;
  const _MoreItem(this.icon, this.label, this.sub, this.onTap);
}
