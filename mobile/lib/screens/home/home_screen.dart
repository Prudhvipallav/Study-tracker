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
  int _waterGoal = 8;
  int _maxStreak = 0;
  String _quote = '';
  List<bool> _weekActivity = List.filled(7, false);
  int _dayNumber = 0;

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
    final water = await db.fetchOne('SELECT water_glasses, water_goal FROM health_logs WHERE date=?', [today]);
    final streakRow = await db.fetchAll('SELECT current_streak FROM habits WHERE is_archived=0');
    final maxStreak = streakRow.isEmpty ? 0 : streakRow.map((h) => (h['current_streak'] as int?) ?? 0).reduce((a, b) => a > b ? a : b);

    // Week activity — check last 7 days for any logged action
    final weekAct = <bool>[];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      final anyLog = await db.fetchOne(
        'SELECT 1 FROM habit_logs WHERE date=? AND is_done=1 UNION SELECT 1 FROM todos WHERE completed_at LIKE ? UNION SELECT 1 FROM health_logs WHERE date=? AND (sleep_hours > 0 OR water_glasses > 0 OR mood IS NOT NULL OR exercise_minutes > 0) LIMIT 1',
        [d, '$d%', d],
      );
      weekAct.add(anyLog != null);
    }

    // Day number — days since profile creation
    int dayNum = 1;
    if (profile != null && profile['created_at'] != null) {
      final created = DateTime.tryParse(profile['created_at'] as String);
      if (created != null) dayNum = DateTime.now().difference(created).inDays + 1;
    }

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
        _waterGoal = (water?['water_goal'] as int?) ?? 8;
        _maxStreak = maxStreak;
        _weekActivity = weekAct;
        _dayNumber = dayNum;
      });
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static const _streamNames = {
    'engineering': 'Engineering',
    'medical': 'Medical',
    'law': 'Law',
    'competitive': 'Competitive',
  };

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
              expandedHeight: 90,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('${_greeting()}, $name! 🌟', style: TextStyle(color: ThemeManager.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Day $_dayNumber of your ${_streamNames[stream] ?? stream} journey',
                      style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
                ]),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Lvl $level', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    StreamBadge(stream: stream),
                  ]),
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
                      gradient: LinearGradient(
                        colors: [ThemeManager.primary.withAlpha(20), ThemeManager.surface],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ThemeManager.border),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('💡 ', style: const TextStyle(fontSize: 18)),
                      Expanded(child: Text('"$_quote"', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13, fontStyle: FontStyle.italic))),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Animated XP bar
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (xp % 500) / 500),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => _buildXpBar(xp, level, val),
                  ),

                  // Mini week calendar strip
                  const SizedBox(height: 12),
                  _buildWeekStrip(),

                  const SizedBox(height: 8),
                  const SectionHeader(title: "Today's Quick Stats"),

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
                      StatCard(icon: '💧', label: 'Water', value: '$_waterToday/$_waterGoal'),
                    ]),
                  ),

                  // Today's Focus
                  if (_topTask != null) ...[
                    const SectionHeader(title: "Today's Focus 🎯"),
                    _buildFocusCard(_topTask!),
                  ],

                  // Habits with streak flames
                  if (_habitsToday.isNotEmpty) ...[
                    const SectionHeader(title: "Today's Habits"),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _habitsToday.length,
                        itemBuilder: (_, i) {
                          final h = _habitsToday[i];
                          final done = h['done'] == true;
                          final streak = (h['current_streak'] as int?) ?? 0;
                          return GestureDetector(
                            onTap: () => _checkHabit(h),
                            child: Container(
                              width: 70, margin: const EdgeInsets.only(right: 10),
                              child: Column(children: [
                                Stack(children: [
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
                                  // Streak flame
                                  if (streak >= 3)
                                    Positioned(top: -2, right: -2, child: Text('🔥', style: const TextStyle(fontSize: 14))),
                                ]),
                                const SizedBox(height: 4),
                                Text(
                                  h['name'] as String? ?? '',
                                  style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11),
                                  overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                ),
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
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpBar(int xp, int level, double progress) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Level $level', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold, fontSize: 13)),
        Text('$xp XP', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(children: [
          Container(height: 10, decoration: BoxDecoration(color: ThemeManager.surface2, borderRadius: BorderRadius.circular(6))),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [ThemeManager.primary, ThemeManager.primary.withAlpha(180)]),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 2),
      Text('${(progress * 100).toInt()}% to Level ${level + 1}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
    ]);
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeManager.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeManager.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final isToday = i == 6;
          final hasActivity = i < _weekActivity.length && _weekActivity[i];
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Text(dayNames[day.weekday - 1], style: TextStyle(
              color: isToday ? ThemeManager.primary : ThemeManager.textSecondary,
              fontSize: 10, fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            )),
            const SizedBox(height: 4),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: hasActivity ? ThemeManager.primary : ThemeManager.surface,
                shape: BoxShape.circle,
                border: isToday ? Border.all(color: ThemeManager.primary, width: 2) : null,
              ),
              child: Center(child: Text(
                '${day.day}',
                style: TextStyle(
                  color: hasActivity ? Colors.white : ThemeManager.textSecondary,
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              )),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: hasActivity ? ThemeManager.success : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ]);
        }),
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
