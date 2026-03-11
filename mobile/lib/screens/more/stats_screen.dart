import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DbHelper.instance;
    final week = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);

    final totalTasks = await db.fetchOne('SELECT COUNT(*) as c FROM todos WHERE is_completed=1');
    final pomoCycles = await db.fetchOne('SELECT SUM(cycles_completed) as s FROM pomodoro_sessions');
    final pomoHours = await db.fetchOne('SELECT SUM(total_focus_minutes) as s FROM pomodoro_sessions');
    final habits = await db.fetchAll('SELECT current_streak, longest_streak, name FROM habits WHERE is_archived=0');
    final badges = await db.fetchOne('SELECT COUNT(*) as c FROM badges');
    final xp = await db.fetchOne('SELECT xp, level FROM profiles LIMIT 1');
    final weeklyPomoData = await db.fetchAll(
        'SELECT date, SUM(total_focus_minutes) as mins FROM pomodoro_sessions WHERE date>=? GROUP BY date ORDER BY date', [week]);

    if (mounted) {
      setState(() => _stats = {
        'total_tasks': (totalTasks?['c'] as int?) ?? 0,
        'pomo_cycles': (pomoCycles?['s'] as int?) ?? 0,
        'focus_hours': (((pomoHours?['s'] as int?) ?? 0) / 60).toStringAsFixed(1),
        'habits': habits,
        'badges': (badges?['c'] as int?) ?? 0,
        'xp': (xp?['xp'] as int?) ?? 0,
        'level': (xp?['level'] as int?) ?? 1,
        'weekly_pomo': weeklyPomoData,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('📈 Stats')),
      body: _stats.isEmpty
          ? Center(child: CircularProgressIndicator(color: ThemeManager.primary))
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Quick stats
              SectionHeader(title: 'All-Time Overview'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  StatCard(icon: '✅', label: 'Tasks Done', value: '${_stats['total_tasks']}'),
                  const SizedBox(width: 10),
                  StatCard(icon: '🍅', label: 'Cycles', value: '${_stats['pomo_cycles']}'),
                  const SizedBox(width: 10),
                  StatCard(icon: '⏱️', label: 'Focus Hrs', value: '${_stats['focus_hours']}'),
                  const SizedBox(width: 10),
                  StatCard(icon: '🏅', label: 'Badges', value: '${_stats['badges']}'),
                  const SizedBox(width: 10),
                  StatCard(icon: '⭐', label: 'Total XP', value: '${_stats['xp']}'),
                ]),
              ),
              SectionHeader(title: '📊 Weekly Focus Minutes'),
              _buildWeeklyChart(),
              SectionHeader(title: '🔥 Habit Streaks'),
              ..._buildHabitStreaks(),
            ]),
    );
  }

  Widget _buildWeeklyChart() {
    final data = _stats['weekly_pomo'] as List<Map<String, dynamic>>? ?? [];
    if (data.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)),
        child: Text('No Pomodoro sessions this week', style: TextStyle(color: ThemeManager.textSecondary)),
      );
    }
    final maxY = data.map((d) => (d['mins'] as num? ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)),
      child: BarChart(BarChartData(
        maxY: maxY + 20,
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(
            toY: (e.value['mins'] as num? ?? 0).toDouble(),
            color: ThemeManager.primary,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          )],
        )).toList(),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt() < dayNames.length ? dayNames[v.toInt()] : '', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)))),
        ),
        barTouchData: BarTouchData(enabled: true),
      )),
    );
  }

  List<Widget> _buildHabitStreaks() {
    final habits = _stats['habits'] as List<Map<String, dynamic>>? ?? [];
    if (habits.isEmpty) return [Padding(padding: const EdgeInsets.all(8), child: Text('No habits tracked yet.', style: TextStyle(color: ThemeManager.textSecondary)))];
    return habits.map((h) {
      final streak = (h['current_streak'] as int?) ?? 0;
      final longest = (h['longest_streak'] as int?) ?? 0;
      final frac = longest > 0 ? streak / longest : 0.0;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(h['name'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold)),
            Text('🔥 $streak d (best: $longest)', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: frac.toDouble(), backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(ThemeManager.primary), minHeight: 6),
        ]),
      );
    }).toList();
  }
}
