import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rows = await DbHelper.instance.fetchAll('SELECT * FROM attendance ORDER BY subject');
    if (mounted) setState(() => _subjects = rows);
  }

  double _pct(Map<String, dynamic> s) {
    final total = (s['total_classes'] as int?) ?? 0;
    final att = (s['attended'] as int?) ?? 0;
    return total > 0 ? att / total : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('📊 Attendance')),
      body: _subjects.isEmpty
          ? EmptyState(icon: '📊', title: 'No subjects', subtitle: 'Add a subject to track attendance.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subjects.length,
              itemBuilder: (_, i) => _subjectCard(_subjects[i]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addSubject,
      ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> s) {
    final pct = _pct(s);
    final required = (s['required_percent'] as int?) ?? 75;
    final color = pct * 100 >= required ? ThemeManager.success : pct * 100 >= required - 10 ? ThemeManager.warning : ThemeManager.danger;
    final attended = (s['attended'] as int?) ?? 0;
    final total = (s['total_classes'] as int?) ?? 0;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(s['subject'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
          Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: pct, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
        const SizedBox(height: 8),
        Text('$attended / $total classes    Required: $required%', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: () async {
              await DbHelper.instance.execute('UPDATE attendance SET total_classes=total_classes+1, attended=attended+1 WHERE id=?', [s['id']]);
              await DbHelper.instance.insert('attendance_logs', {'attendance_id': s['id'], 'date': today, 'status': 'present'});
              await DbHelper.instance.awardXp(2, 'log_attendance');
              _load();
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Present'),
            style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.success, padding: const EdgeInsets.symmetric(vertical: 10)),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () async {
              await DbHelper.instance.execute('UPDATE attendance SET total_classes=total_classes+1 WHERE id=?', [s['id']]);
              await DbHelper.instance.insert('attendance_logs', {'attendance_id': s['id'], 'date': today, 'status': 'absent'});
              _load();
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Absent'),
            style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.danger, padding: const EdgeInsets.symmetric(vertical: 10)),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () async {
              await DbHelper.instance.execute('UPDATE attendance SET total_classes=total_classes+1 WHERE id=?', [s['id']]);
              await DbHelper.instance.insert('attendance_logs', {'attendance_id': s['id'], 'date': today, 'status': 'cancelled'});
              _load();
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('No Class'),
            style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.surface, foregroundColor: ThemeManager.textSecondary, padding: const EdgeInsets.symmetric(vertical: 10)),
          )),
        ]),
        if (pct * 100 < required && total > 5) ...[
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final needToAttend = ((required / 100 * total) - attended).ceil();
            return Text('⚠️ Attend next $needToAttend classes to reach $required%', style: TextStyle(color: ThemeManager.warning, fontSize: 12));
          }),
        ],
      ]),
    );
  }

  void _addSubject() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Subject', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Subject name…')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('attendance', {'subject': ctrl.text.trim(), 'required_percent': 75});
              Navigator.pop(context); _load();
            },
            child: const Text('Add Subject'),
          )),
        ]),
      ),
    );
  }
}
