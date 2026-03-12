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
  int? _selectedSubjectId;
  List<Map<String, dynamic>> _calendarLogs = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rows = await DbHelper.instance.fetchAll('SELECT * FROM attendance ORDER BY subject');
    if (mounted) setState(() => _subjects = rows);
    if (_selectedSubjectId != null) _loadCalendar(_selectedSubjectId!);
  }

  double _pct(Map<String, dynamic> s) {
    final total = (s['total_classes'] as int?) ?? 0;
    final att = (s['attended'] as int?) ?? 0;
    return total > 0 ? att / total : 0;
  }

  Future<void> _loadCalendar(int attendanceId) async {
    final logs = await DbHelper.instance.fetchAll(
      'SELECT * FROM attendance_logs WHERE attendance_id=? ORDER BY date DESC',
      [attendanceId],
    );
    if (mounted) setState(() => _calendarLogs = logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('📊 Attendance')),
      body: _subjects.isEmpty
          ? EmptyState(icon: '📊', title: 'No subjects', subtitle: 'Add a subject to track attendance.')
          : Column(children: [
              // Subject filter chips
              _buildSubjectFilter(),
              Expanded(child: _selectedSubjectId == null ? _buildAllSubjects() : _buildSubjectDetail()),
            ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addSubject,
      ),
    );
  }

  // ── Subject filter chips ──────────────────────────────────────────────────

  Widget _buildSubjectFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _filterChip(null, '📋 All Subjects'),
          ..._subjects.map((s) => _filterChip(s['id'] as int, s['subject'] as String? ?? '')),
        ]),
      ),
    );
  }

  Widget _filterChip(int? id, String label) {
    final selected = _selectedSubjectId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedSubjectId = id);
          if (id != null) _loadCalendar(id);
        },
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
      ),
    );
  }

  // ── All subjects list ─────────────────────────────────────────────────────

  Widget _buildAllSubjects() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (_, i) => _subjectCard(_subjects[i]),
    );
  }

  // ── Single subject detail with calendar ───────────────────────────────────

  Widget _buildSubjectDetail() {
    final subject = _subjects.firstWhere((s) => s['id'] == _selectedSubjectId, orElse: () => {});
    if (subject.isEmpty) return const SizedBox.shrink();

    final pct = _pct(subject);
    final required = (subject['required_percent'] as int?) ?? 75;
    final attended = (subject['attended'] as int?) ?? 0;
    final total = (subject['total_classes'] as int?) ?? 0;
    final color = pct * 100 >= required ? ThemeManager.success : pct * 100 >= required - 10 ? ThemeManager.warning : ThemeManager.danger;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Calculate can-miss / need-more
    String adviceText = '';
    if (total > 0) {
      final neededClasses = (required / 100 * total).ceil();
      if (attended >= neededClasses) {
        final canMiss = ((attended - required / 100 * total) / (1 - required / 100)).floor();
        adviceText = '✅ You can miss $canMiss more classes and stay above $required%';
      } else {
        final needMore = neededClasses - attended;
        adviceText = '⚠️ You need to attend $needMore more classes to reach $required%';
      }
    }

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(100))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(subject['subject'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: pct, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
          const SizedBox(height: 6),
          Text('$attended / $total classes    Required: $required%', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          if (adviceText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(adviceText, style: TextStyle(color: adviceText.startsWith('✅') ? ThemeManager.success : ThemeManager.warning, fontSize: 12)),
          ],
        ]),
      ),

      // Mark buttons
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () async {
            await DbHelper.instance.execute('UPDATE attendance SET total_classes=total_classes+1, attended=attended+1 WHERE id=?', [subject['id']]);
            await DbHelper.instance.insert('attendance_logs', {'attendance_id': subject['id'], 'date': today, 'status': 'present'});
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
            await DbHelper.instance.execute('UPDATE attendance SET total_classes=total_classes+1 WHERE id=?', [subject['id']]);
            await DbHelper.instance.insert('attendance_logs', {'attendance_id': subject['id'], 'date': today, 'status': 'absent'});
            _load();
          },
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Absent'),
          style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.danger, padding: const EdgeInsets.symmetric(vertical: 10)),
        )),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(
          onPressed: () async {
            await DbHelper.instance.execute('UPDATE attendance SET total_classes=total_classes+1 WHERE id=?', [subject['id']]);
            await DbHelper.instance.insert('attendance_logs', {'attendance_id': subject['id'], 'date': today, 'status': 'cancelled'});
            _load();
          },
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('No Class'),
          style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.surface, foregroundColor: ThemeManager.textSecondary, padding: const EdgeInsets.symmetric(vertical: 10)),
        )),
      ]),

      // Calendar view
      const SizedBox(height: 20),
      const SectionHeader(title: '📅 Attendance Calendar'),
      _buildCalendar(),

      // Log history
      const SizedBox(height: 16),
      const SectionHeader(title: '📋 Recent Logs'),
      ..._calendarLogs.take(15).map((log) {
        final status = log['status'] as String? ?? '';
        final date = log['date'] as String? ?? '';
        final icon = status == 'present' ? '🟩' : status == 'absent' ? '🟥' : '⬜';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(date, style: TextStyle(color: ThemeManager.textColor, fontSize: 13)),
            const SizedBox(width: 8),
            Text(status.toUpperCase(), style: TextStyle(
              color: status == 'present' ? ThemeManager.success : status == 'absent' ? ThemeManager.danger : ThemeManager.textSecondary,
              fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ]),
        );
      }),
    ]));
  }

  // ── Calendar grid ─────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday; // 1=Mon, 7=Sun

    // Build map of date → status
    final statusMap = <String, String>{};
    for (final log in _calendarLogs) {
      final d = log['date'] as String? ?? '';
      if (d.isNotEmpty) statusMap[d] = log['status'] as String? ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        // Month header
        Text('${_monthName(now.month)} ${now.year}', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        // Day labels
        Row(children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((d) =>
          Expanded(child: Center(child: Text(d, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10, fontWeight: FontWeight.w600))))
        ).toList()),
        const SizedBox(height: 4),
        // Calendar grid
        ...List.generate(6, (week) {
          return Row(children: List.generate(7, (dayOfWeek) {
            final dayNum = week * 7 + dayOfWeek - startWeekday + 2;
            if (dayNum < 1 || dayNum > daysInMonth) return const Expanded(child: SizedBox(height: 32));
            final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
            final status = statusMap[dateStr];
            Color cellColor;
            if (status == 'present') {
              cellColor = ThemeManager.success;
            } else if (status == 'absent') {
              cellColor = ThemeManager.danger;
            } else if (status == 'cancelled') {
              cellColor = ThemeManager.surface2;
            } else {
              cellColor = Colors.transparent;
            }
            final isToday = dayNum == now.day;
            return Expanded(child: Container(
              height: 32, margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: cellColor.withAlpha(status != null ? 60 : 0),
                borderRadius: BorderRadius.circular(6),
                border: isToday ? Border.all(color: ThemeManager.primary, width: 2) : null,
              ),
              child: Center(child: Text(
                '$dayNum',
                style: TextStyle(
                  color: status == 'present' ? ThemeManager.success : status == 'absent' ? ThemeManager.danger : ThemeManager.textColor,
                  fontSize: 12,
                  fontWeight: isToday || status != null ? FontWeight.bold : FontWeight.normal,
                ),
              )),
            ));
          }));
        }),
      ]),
    );
  }

  String _monthName(int m) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[m];
  }

  // ── Subject card (used in All Subjects view) ──────────────────────────────

  Widget _subjectCard(Map<String, dynamic> s) {
    final pct = _pct(s);
    final required = (s['required_percent'] as int?) ?? 75;
    final color = pct * 100 >= required ? ThemeManager.success : pct * 100 >= required - 10 ? ThemeManager.warning : ThemeManager.danger;
    final attended = (s['attended'] as int?) ?? 0;
    final total = (s['total_classes'] as int?) ?? 0;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedSubjectId = s['id'] as int);
        _loadCalendar(s['id'] as int);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeManager.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(100)),
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
      ),
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
