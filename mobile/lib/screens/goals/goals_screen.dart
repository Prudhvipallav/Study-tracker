import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _activeGoals = [];
  List<Map<String, dynamic>> _completedGoals = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final active = await DbHelper.instance.fetchAll('SELECT * FROM goals WHERE is_completed=0 ORDER BY deadline');
    final done = await DbHelper.instance.fetchAll('SELECT * FROM goals WHERE is_completed=1 ORDER BY created_at DESC');
    if (mounted) setState(() { _activeGoals = active; _completedGoals = done; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(
        title: const Text('🎯 Goals'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: ThemeManager.primary,
          labelColor: ThemeManager.primary,
          unselectedLabelColor: ThemeManager.textSecondary,
          tabs: [Tab(text: 'Active (${_activeGoals.length})'), Tab(text: 'Completed (${_completedGoals.length})')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _buildGoalList(_activeGoals, isEmpty: 'No active goals yet — tap + to create one!'),
        _buildGoalList(_completedGoals, isEmpty: 'No completed goals yet.'),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGoal,
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGoalList(List<Map<String, dynamic>> goals, {required String isEmpty}) {
    if (goals.isEmpty) {
      return EmptyState(icon: '🎯', title: 'No goals', subtitle: isEmpty);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (_, i) => GoalProgressCard(
        goal: goals[i],
        onTap: () => _openGoal(goals[i]),
      ),
    );
  }

  // ── Create Goal ────────────────────────────────────────────────────────────

  void _createGoal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'short';
    DateTime? deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Goal', style: TextStyle(color: ThemeManager.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          TextField(
            controller: titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Goal title…', prefixIcon: Icon(Icons.flag)),
            style: TextStyle(color: ThemeManager.textColor),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(hintText: 'Description (optional)…', prefixIcon: Icon(Icons.notes)),
            style: TextStyle(color: ThemeManager.textColor),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Text('Goal Type', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _typeChip('short', '🏃 Short-term', type, (t) => setS(() => type = t)),
            const SizedBox(width: 8),
            _typeChip('long', '🎯 Long-term', type, (t) => setS(() => type = t)),
          ]),
          const SizedBox(height: 16),

          // Deadline picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setS(() => deadline = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: ThemeManager.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeManager.border),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today, color: ThemeManager.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  deadline != null ? '${deadline!.day}/${deadline!.month}/${deadline!.year}' : 'Set deadline (optional)',
                  style: TextStyle(color: deadline != null ? ThemeManager.textColor : ThemeManager.textSecondary, fontSize: 14),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('goals', {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'type': type,
                'deadline': deadline?.toIso8601String().substring(0, 10),
                'progress_percent': 0,
                'is_completed': 0,
              });
              await DbHelper.instance.awardXp(10, 'create_goal');
              if (mounted) Navigator.pop(context);
              _showSnack('🎯 Goal created! +10 XP');
              _load();
            },
            icon: const Icon(Icons.check),
            label: const Text('Create Goal'),
          )),
        ]))),
      ),
    );
  }

  Widget _typeChip(String value, String label, String current, ValueChanged<String> onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ThemeManager.primary.withAlpha(40) : ThemeManager.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? ThemeManager.primary : ThemeManager.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? ThemeManager.primary : ThemeManager.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        )),
      ),
    );
  }

  // ── Goal Detail Sheet ──────────────────────────────────────────────────────

  void _openGoal(Map<String, dynamic> goal) async {
    final milestones = await DbHelper.instance.fetchAll('SELECT * FROM milestones WHERE goal_id=? ORDER BY order_index', [goal['id']]);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (ctx, scrollCtrl) => StatefulBuilder(builder: (ctx2, setSheet) {
          // Recalculate progress from milestones
          final totalMs = milestones.length;
          final doneMs = milestones.where((m) => m['is_completed'] == 1).length;
          final progress = totalMs > 0 ? (doneMs / totalMs * 100).toInt() : (goal['progress_percent'] as int?) ?? 0;

          return SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title + Complete button
              Row(children: [
                Expanded(child: Text(goal['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontSize: 20, fontWeight: FontWeight.bold))),
                if (goal['is_completed'] != 1)
                  IconButton(
                    icon: Icon(Icons.check_circle_outline, color: ThemeManager.success),
                    tooltip: 'Complete Goal',
                    onPressed: () async {
                      await DbHelper.instance.updateWhere('goals', {'is_completed': 1, 'progress_percent': 100}, 'id=?', [goal['id']]);
                      await DbHelper.instance.awardXp(100, 'complete_goal');
                      if (mounted) Navigator.pop(context);
                      _showSnack('🏆 Goal completed! +100 XP');
                      _load();
                    },
                  ),
              ]),

              if (goal['description'] != null && (goal['description'] as String).isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(goal['description'] as String? ?? '', style: TextStyle(color: ThemeManager.textSecondary))),

              if (goal['deadline'] != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.calendar_today, size: 14, color: ThemeManager.textSecondary),
                  const SizedBox(width: 4),
                  Text('Deadline: ${goal['deadline']}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
                ]),
              ],

              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress / 100, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(ThemeManager.primary), minHeight: 8),
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('$progress% complete ($doneMs/$totalMs milestones)', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),

              const SizedBox(height: 24),

              // Milestones header + add button
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Milestones', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: () => _addMilestone(goal['id'] as int, milestones.length, setSheet, milestones),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ]),

              if (milestones.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No milestones yet — add some to track progress!', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
                ),

              ...milestones.map((m) => CheckboxListTile(
                value: m['is_completed'] == 1,
                activeColor: ThemeManager.primary,
                title: Text(
                  m['title'] as String? ?? '',
                  style: TextStyle(
                    color: ThemeManager.textColor,
                    decoration: m['is_completed'] == 1 ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: m['deadline'] != null
                    ? Text('Due: ${m['deadline']}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11))
                    : null,
                onChanged: (v) async {
                  await DbHelper.instance.updateWhere('milestones', {'is_completed': v == true ? 1 : 0}, 'id=?', [m['id']]);
                  if (v == true) {
                    await DbHelper.instance.awardXp(25, 'complete_milestone');
                    _showSnack('⭐ Milestone done! +25 XP');
                  }
                  // Recalculate goal progress
                  final allMs = await DbHelper.instance.fetchAll('SELECT * FROM milestones WHERE goal_id=?', [goal['id']]);
                  final doneCount = allMs.where((ms) => ms['is_completed'] == 1).length;
                  final newPct = allMs.isNotEmpty ? (doneCount / allMs.length * 100).toInt() : 0;
                  await DbHelper.instance.updateWhere('goals', {'progress_percent': newPct}, 'id=?', [goal['id']]);
                  // Update sheet state
                  milestones.clear();
                  milestones.addAll(allMs);
                  setSheet(() {});
                  _load();
                },
              )),

              // Delete goal
              const SizedBox(height: 24),
              Center(child: TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx2,
                    builder: (d) => AlertDialog(
                      title: const Text('Delete Goal?'),
                      content: const Text('This will permanently remove this goal and its milestones.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(d, true), child: Text('Delete', style: TextStyle(color: ThemeManager.danger))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await DbHelper.instance.deleteWhere('milestones', 'goal_id=?', [goal['id']]);
                    await DbHelper.instance.deleteWhere('goals', 'id=?', [goal['id']]);
                    if (mounted) Navigator.pop(context);
                    _showSnack('Goal deleted');
                    _load();
                  }
                },
                icon: Icon(Icons.delete_outline, color: ThemeManager.danger, size: 18),
                label: Text('Delete Goal', style: TextStyle(color: ThemeManager.danger)),
              )),
            ]),
          );
        }),
      ),
    );
  }

  void _addMilestone(int goalId, int order, StateSetter setSheet, List<Map<String, dynamic>> milestones) {
    final ctrl = TextEditingController();
    DateTime? deadline;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setD) => AlertDialog(
        backgroundColor: ThemeManager.card,
        title: Text('Add Milestone', style: TextStyle(color: ThemeManager.textColor)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Milestone title…'),
            style: TextStyle(color: ThemeManager.textColor),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx2,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setD(() => deadline = picked);
            },
            child: Row(children: [
              Icon(Icons.calendar_today, size: 16, color: ThemeManager.textSecondary),
              const SizedBox(width: 8),
              Text(deadline != null ? '${deadline!.day}/${deadline!.month}/${deadline!.year}' : 'Set deadline (optional)',
                  style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('milestones', {
                'goal_id': goalId,
                'title': ctrl.text.trim(),
                'deadline': deadline?.toIso8601String().substring(0, 10),
                'is_completed': 0,
                'order_index': order,
              });
              Navigator.pop(ctx);
              // Refresh milestones
              final allMs = await DbHelper.instance.fetchAll('SELECT * FROM milestones WHERE goal_id=? ORDER BY order_index', [goalId]);
              milestones.clear();
              milestones.addAll(allMs);
              setSheet(() {});
              _load();
            },
            child: const Text('Add'),
          ),
        ],
      )),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }
}
