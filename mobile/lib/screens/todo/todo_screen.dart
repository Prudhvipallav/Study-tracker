import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> _todos = [];
  String _filter = 'All';
  static const _filters = ['All', 'Today', 'This Week', 'High Priority', 'Completed'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final weekEnd = DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    String q = 'SELECT * FROM todos';
    List<dynamic> args = [];
    switch (_filter) {
      case 'Today': q += ' WHERE due_date=? AND is_completed=0'; args = [today]; break;
      case 'This Week': q += ' WHERE due_date BETWEEN ? AND ? AND is_completed=0'; args = [today, weekEnd]; break;
      case 'High Priority': q += " WHERE priority IN ('high','urgent') AND is_completed=0"; break;
      case 'Completed': q += ' WHERE is_completed=1'; break;
      default: q += ' WHERE is_completed=0'; break;
    }
    q += ' ORDER BY CASE priority WHEN \'urgent\' THEN 0 WHEN \'high\' THEN 1 WHEN \'medium\' THEN 2 ELSE 3 END, due_date';
    final rows = await DbHelper.instance.fetchAll(q, args);
    if (mounted) setState(() => _todos = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('✅ To-Do List')),
      body: Column(children: [
        _filterChips(),
        Expanded(
          child: _todos.isEmpty
              ? EmptyState(icon: '✅', title: 'All clear!', subtitle: 'Add a task to get started.')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _todos.length,
                  itemBuilder: (_, i) => _taskCard(_todos[i]),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: _filter == f,
            onSelected: (_) { setState(() => _filter = f); _load(); },
            selectedColor: ThemeManager.primary,
            backgroundColor: ThemeManager.surface,
            labelStyle: TextStyle(color: _filter == f ? Colors.white : ThemeManager.textSecondary, fontSize: 12),
          ),
        )).toList(),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final due = task['due_date'] as String?;
    final overdue = due != null && due.compareTo(today) < 0 && task['is_completed'] == 0;
    final pColors = {'urgent': ThemeManager.danger, 'high': ThemeManager.warning, 'medium': ThemeManager.primary, 'low': ThemeManager.success};
    final pColor = pColors[task['priority']] ?? ThemeManager.primary;

    return Dismissible(
      key: Key('todo_${task['id']}'),
      background: Container(
        alignment: Alignment.centerLeft, color: ThemeManager.success, padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight, color: ThemeManager.danger, padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await DbHelper.instance.updateWhere('todos', {'is_completed': 1, 'completed_at': DateTime.now().toIso8601String()}, 'id=?', [task['id']]);
          await DbHelper.instance.awardXp(10, 'complete_task');
          HapticFeedback.mediumImpact();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('+10 XP ⭐'), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 1)));
        } else {
          await DbHelper.instance.deleteWhere('todos', 'id=?', [task['id']]);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Task "${task['title']}" deleted'),
              action: SnackBarAction(label: 'Undo', onPressed: () async {
                await DbHelper.instance.insert('todos', task);
                _load();
              }),
              duration: const Duration(seconds: 3),
            ));
          }
        }
        await _load();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: overdue ? ThemeManager.danger.withAlpha(20) : ThemeManager.card,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: pColor, width: 4)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: GestureDetector(
            onTap: () async {
              await DbHelper.instance.updateWhere('todos', {'is_completed': 1, 'completed_at': DateTime.now().toIso8601String()}, 'id=?', [task['id']]);
              await DbHelper.instance.awardXp(10, 'complete_task');
              HapticFeedback.mediumImpact();
              await _load();
            },
            child: Icon(task['is_completed'] == 1 ? Icons.check_circle : Icons.radio_button_unchecked, color: pColor, size: 26),
          ),
          title: Text(task['title'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.w600, decoration: task['is_completed'] == 1 ? TextDecoration.lineThrough : null, decorationColor: ThemeManager.textSecondary)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (due != null) Text(overdue ? '⚠️ Overdue: $due' : 'Due: $due', style: TextStyle(color: overdue ? ThemeManager.danger : ThemeManager.textSecondary, fontSize: 11)),
            if (task['tags'] != null && (task['tags'] as String).isNotEmpty)
              Text('#${(task['tags'] as String).replaceAll(',', ' #')}', style: TextStyle(color: ThemeManager.primary, fontSize: 11)),
          ]),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: pColor.withAlpha(38), borderRadius: BorderRadius.circular(8)),
            child: Text((task['priority'] as String? ?? 'medium').toUpperCase(), style: TextStyle(color: pColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _addTask() {
    final titleCtrl = TextEditingController();
    String priority = 'medium';
    String due = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Task', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Task title…'), style: TextStyle(color: ThemeManager.textColor)),
          const SizedBox(height: 12),
          Row(children: ['low', 'medium', 'high', 'urgent'].map((p) {
            final isSelected = priority == p;
            final colors = {'urgent': ThemeManager.danger, 'high': ThemeManager.warning, 'medium': ThemeManager.primary, 'low': ThemeManager.success};
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) => setS(() => priority = p),
                selectedColor: colors[p],
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('todos', {'title': titleCtrl.text.trim(), 'priority': priority, 'due_date': due.isNotEmpty ? due : null});
              Navigator.pop(context);
              _load();
            },
            child: const Text('Add Task'),
          )),
        ])),
      ),
    );
  }
}
