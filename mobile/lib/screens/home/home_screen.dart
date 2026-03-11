import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';
import '../../services/quote_service.dart';
import '../countdown/countdown_screen.dart';
import '../goals/goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _habitsToday = [];
  List<Map<String, dynamic>> _countdowns = [];
  List<Map<String, dynamic>> _goals = [];
  Map<String, dynamic>? _topTask;
  int _tasksDoneToday = 0;
  int _pomosToday = 0;
  int _waterToday = 0;
  int _maxStreak = 0;
  String _quote = '';

  @override
  void initState() {
    super.initState();
    _quote = QuoteService.random();
    _load();
  }

  Future<void> _load() async {
    final db = DbHelper.instance;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final profile = await db.fetchOne('SELECT * FROM profiles LIMIT 1');
    final habits = await db.fetchAll('SELECT * FROM habits WHERE is_archived=0');
    final habitLogs = await db.fetchAll('SELECT habit_id FROM habit_logs WHERE date=? AND is_done=1', [today]);
    final doneTodayIds = habitLogs.map((h) => h['habit_id']).toSet();
    final countdowns = await db.fetchAll('SELECT * FROM countdowns WHERE is_archived=0 ORDER BY exam_date LIMIT 3');
    final goals = await db.fetchAll('SELECT * FROM goals WHERE is_completed=0 ORDER BY deadline LIMIT 2');
    final topTask = await db.fetchOne(
        'SELECT * FROM todos WHERE is_completed=0 AND (due_date=? OR due_date IS NULL) ORDER BY CASE priority WHEN \'urgent\' THEN 0 WHEN \'high\' THEN 1 WHEN \'medium\' THEN 2 ELSE 3 END LIMIT 1',
        [today]);
    final tasksDone = await db.fetchOne('SELECT COUNT(*) as c FROM todos WHERE is_completed=1 AND completed_at LIKE ?', ['$today%']);
    final pomos = await db.fetchOne('SELECT SUM(cycles_completed) as s FROM pomodoro_sessions WHERE date=?', [today]);
    final water = await db.fetchOne('SELECT water_glasses FROM health_logs WHERE date=?', [today]);
    final streakRow = await db.fetchAll('SELECT current_streak FROM habits WHERE is_archived=0');
    final maxStreak = streakRow.isEmpty ? 0 : streakRow.map((h) => (h['current_streak'] as int?) ?? 0).reduce((a, b) => a > b ? a : b);

    if (mounted) {
      setState(() {
        _profile = profile;
        _habitsToday = habits.map((h) => {...h, 'done': doneTodayIds.contains(h['id'])}).toList();
        _countdowns = countdowns;
        _goals = goals;
        _topTask = topTask;
        _tasksDoneToday = (tasksDone?['c'] as int?) ?? 0;
        _pomosToday = (pomos?['s'] as int?) ?? 0;
        _waterToday = (water?['water_glasses'] as int?) ?? 0;
        _maxStreak = maxStreak;
      });
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? '';
    final xp = (_profile?['xp'] as int?) ?? 0;
    final level = (_profile?['level'] as int?) ?? 1;
    final stream = (_profile?['stream'] as String?) ?? 'engineering';

    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: ThemeManager.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: ThemeManager.surface,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_greeting()}, $name! 🌟', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                StreamBadge(stream: stream),
              ]),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text('Lvl $level', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Quote
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ThemeManager.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ThemeManager.border),
                    ),
                    child: Text('"$_quote"', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 16),
                  XpBarWidget(xp: xp, level: level),
                  SectionHeader(title: 'Today\'s Quick Stats'),
                  // Stats row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      StatCard(icon: '✅', label: 'Tasks Done', value: '$_tasksDoneToday'),
                      const SizedBox(width: 10),
                      StatCard(icon: '🔥', label: 'Streak', value: '${_maxStreak}d'),
                      const SizedBox(width: 10),
                      StatCard(icon: '🍅', label: 'Pomodoros', value: '$_pomosToday'),
                      const SizedBox(width: 10),
                      StatCard(icon: '💧', label: 'Water', value: '$_waterToday/8'),
                    ]),
                  ),
                  if (_habitsToday.isNotEmpty) ...[
                    SectionHeader(title: "Today's Habits"),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _habitsToday.length,
                        itemBuilder: (_, i) {
                          final h = _habitsToday[i];
                          final done = h['done'] == true;
                          return GestureDetector(
                            onTap: () => _checkHabit(h),
                            child: Container(
                              width: 70, margin: const EdgeInsets.only(right: 10),
                              child: Column(children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 54, height: 54,
                                  decoration: BoxDecoration(
                                    color: done ? ThemeManager.primary : ThemeManager.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: done ? ThemeManager.primary : ThemeManager.border, width: 2),
                                  ),
                                  child: Center(child: Text(
                                    done ? '✓' : (h['icon'] as String? ?? '🔁'),
                                    style: TextStyle(fontSize: done ? 20 : 24, color: done ? Colors.white : null),
                                  )),
                                ),
                                const SizedBox(height: 4),
                                Text(h['name'] as String? ?? '', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_countdowns.isNotEmpty) ...[
                    SectionHeader(title: 'Upcoming Exams', action: 'View all', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CountdownScreen()))),
                    ..._countdowns.map((e) => CountdownCard(exam: e)),
                  ],
                  if (_goals.isNotEmpty) ...[
                    SectionHeader(title: 'Your Goals', action: 'View all', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()))),
                    ..._goals.map((g) => GoalProgressCard(goal: g)),
                  ],
                  if (_topTask != null) ...[
                    SectionHeader(title: "Today's Focus 🎯"),
                    _buildFocusCard(_topTask!),
                  ],
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkHabit(Map<String, dynamic> h) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final done = h['done'] == true;
    if (!done) {
      await DbHelper.instance.insert('habit_logs', {'habit_id': h['id'], 'date': today, 'is_done': 1});
      await DbHelper.instance.awardXp(5, 'habit_checkin');
    }
    await _load();
  }

  Widget _buildFocusCard(Map<String, dynamic> task) {
    final pColors = {'urgent': ThemeManager.danger, 'high': ThemeManager.warning, 'medium': ThemeManager.primary, 'low': ThemeManager.success};
    final pColor = pColors[task['priority']] ?? ThemeManager.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: pColor, width: 4)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
          if (task['due_date'] != null)
            Text('Due: ${task['due_date']}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
        ])),
        ElevatedButton(
          onPressed: () => _completeTask(task),
          style: ElevatedButton.styleFrom(backgroundColor: pColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          child: const Text('Done', style: TextStyle(fontSize: 13)),
        ),
      ]),
    );
  }

  Future<void> _completeTask(Map<String, dynamic> task) async {
    await DbHelper.instance.updateWhere('todos', {'is_completed': 1, 'completed_at': DateTime.now().toIso8601String()}, 'id=?', [task['id']]);
    await DbHelper.instance.awardXp(10, 'complete_task');
    _showXpToast('+10 XP ⭐');
    await _load();
  }

  void _showXpToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1), backgroundColor: ThemeManager.primary),
    );
  }
}
