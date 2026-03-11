import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rows = await DbHelper.instance.fetchAll('SELECT * FROM goals WHERE is_completed=0 ORDER BY deadline');
    if (mounted) setState(() => _goals = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('🎯 Goals')),
      body: _goals.isEmpty
          ? EmptyState(icon: '🎯', title: 'No active goals', subtitle: 'Your goals are set in the desktop app.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              itemBuilder: (_, i) => GoalProgressCard(
                goal: _goals[i],
                onTap: () => _openGoal(_goals[i]),
              ),
            ),
    );
  }

  void _openGoal(Map<String, dynamic> goal) async {
    final milestones = await DbHelper.instance.fetchAll('SELECT * FROM milestones WHERE goal_id=? ORDER BY order_index', [goal['id']]);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(goal['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            if (goal['description'] != null && (goal['description'] as String).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(goal['description'] as String? ?? '', style: TextStyle(color: ThemeManager.textSecondary))),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: ((goal['progress_percent'] as int?) ?? 0) / 100, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(ThemeManager.primary), minHeight: 8),
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('${goal['progress_percent']}% complete', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
            const SizedBox(height: 24),
            Text('Milestones', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ...milestones.map((m) => StatefulBuilder(builder: (ms, setMs) => CheckboxListTile(
              value: m['is_completed'] == 1,
              activeColor: ThemeManager.primary,
              title: Text(m['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, decoration: m['is_completed'] == 1 ? TextDecoration.lineThrough : null)),
              onChanged: (v) async {
                await DbHelper.instance.updateWhere('milestones', {'is_completed': v == true ? 1 : 0}, 'id=?', [m['id']]);
                if (v == true) await DbHelper.instance.awardXp(25, 'complete_milestone');
                _load();
              },
            ))),
          ]),
        ),
      ),
    );
  }
}
