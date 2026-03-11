import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});
  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rows = await DbHelper.instance.fetchAll('SELECT * FROM countdowns WHERE is_archived=0 ORDER BY exam_date');
    if (mounted) setState(() => _items = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('⏰ Exam Countdowns')),
      body: _items.isEmpty
          ? EmptyState(icon: '⏰', title: 'No exams added', subtitle: 'Add your next exam to count down!')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) => CountdownCard(
                exam: _items[i],
                onDelete: () async { await DbHelper.instance.updateWhere('countdowns', {'is_archived': 1}, 'id=?', [_items[i]['id']]); _load(); },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addCountdown,
      ),
    );
  }

  void _addCountdown() {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Exam', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Exam name…')),
          const SizedBox(height: 12),
          TextField(controller: subjectCtrl, decoration: const InputDecoration(hintText: 'Subject (optional)…')),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
              if (picked != null) setS(() => selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ThemeManager.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.calendar_today, color: ThemeManager.primary),
                const SizedBox(width: 12),
                Text('📅 ${selectedDate.toIso8601String().substring(0, 10)}', style: TextStyle(color: ThemeManager.textColor)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('countdowns', {'title': titleCtrl.text.trim(), 'subject': subjectCtrl.text.trim(), 'exam_date': selectedDate.toIso8601String().substring(0, 10)});
              Navigator.pop(context); _load();
            },
            child: const Text('Add Exam'),
          )),
        ])),
      ),
    );
  }
}
