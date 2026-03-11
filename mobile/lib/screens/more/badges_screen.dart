import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  Set<String> _earned = {};

  static const _allBadges = [
    ('first_task', '✅', 'First Task Done!'),
    ('task_machine', '⚡', 'Task Machine'),
    ('streak_3', '🔥', '3-Day Streak'),
    ('streak_7', '🏅', 'Week Warrior'),
    ('streak_30', '💎', 'Unstoppable'),
    ('first_goal', '🎯', 'Goal Setter'),
    ('goal_crusher', '🏆', 'Goal Crusher'),
    ('milestone_master', '⭐', 'Milestone Master'),
    ('pomodoro_10', '🍅', 'Focus Machine'),
    ('pomodoro_50', '🎖️', 'Pomodoro Master'),
    ('note_taker', '📝', 'Note Taker'),
    ('deck_creator', '🃏', 'Knowledge Seeker'),
    ('flashcard_master', '🧠', 'Flashcard Master'),
    ('level_5', '⭐', 'Rising Star'),
    ('level_10', '👑', 'Legend'),
    ('attendance_perfect', '🎓', 'Perfect Attendee'),
    ('health_week', '❤️', 'Health Champion'),
    ('hydrated', '💧', 'Hydration Hero'),
    ('athlete', '🏃', 'Athlete'),
    ('early_bird', '🌅', 'Early Bird'),
    ('night_owl', '🦉', 'Night Owl'),
    ('exam_survivor', '🎓', 'Exam Survivor'),
    ('consistent', '📅', 'Consistent Learner'),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rows = await DbHelper.instance.fetchAll('SELECT badge_key FROM badges');
    if (mounted) setState(() => _earned = rows.map((r) => r['badge_key'] as String).toSet());
  }

  @override
  Widget build(BuildContext context) {
    final earned = _allBadges.where((b) => _earned.contains(b.$1)).length;
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('🏅 Badges')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: ThemeManager.surface,
          child: Column(children: [
            Text('$earned / ${_allBadges.length} badges unlocked', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: earned / _allBadges.length, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(ThemeManager.primary), minHeight: 8),
          ]),
        ),
        Expanded(child: GridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: _allBadges.map((b) => BadgeCard(
            icon: b.$2,
            name: b.$3,
            earned: _earned.contains(b.$1),
            onTap: () => _earnedToast(b.$3, _earned.contains(b.$1)),
          )).toList(),
        )),
      ]),
    );
  }

  void _earnedToast(String name, bool earned) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(earned ? '🏅 $name — Earned!' : '🔒 $name — Keep going to unlock!'),
      backgroundColor: earned ? ThemeManager.primary : ThemeManager.surface,
      duration: const Duration(seconds: 2),
    ));
  }
}
