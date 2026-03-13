import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _habits = [];
  Set<int> _doneToday = {};
  final _today = DateTime.now().toIso8601String().substring(0, 10);
  Map<String, Map<int, String>> _heatmapData = {}; // date -> {habitId -> status}
  int? _heatmapHabitId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final habits = await DbHelper.instance.fetchAll('SELECT * FROM habits WHERE is_archived=0 ORDER BY created_at');
    final logs = await DbHelper.instance.fetchAll('SELECT habit_id FROM habit_logs WHERE date=? AND is_done=1', [_today]);
    if (mounted) setState(() { _habits = habits; _doneToday = logs.map((l) => l['habit_id'] as int).toSet(); });
    if (_heatmapHabitId != null || _habits.isNotEmpty) {
      _loadHeatmap(_heatmapHabitId ?? (_habits.isNotEmpty ? _habits.first['id'] as int : null));
    }
  }

  Future<void> _loadHeatmap(int? habitId) async {
    if (habitId == null) return;
    _heatmapHabitId = habitId;
    final fiveWeeksAgo = DateTime.now().subtract(const Duration(days: 35));
    final logs = await DbHelper.instance.fetchAll(
      'SELECT date, is_done, note FROM habit_logs WHERE habit_id=? AND date>=? ORDER BY date',
      [habitId, fiveWeeksAgo.toIso8601String().substring(0, 10)],
    );
    final dataMap = <String, Map<int, String>>{};
    for (final log in logs) {
      final date = log['date'] as String? ?? '';
      final done = (log['is_done'] as int?) ?? 0;
      final note = log['note'] as String? ?? '';
      String status = done == 1 ? (note.contains('[irregular]') ? 'irregular' : 'done') : 'missed';
      dataMap[date] = {habitId: status};
    }
    if (mounted) setState(() => _heatmapData = dataMap);
  }

  @override
  Widget build(BuildContext context) {
    final done = _doneToday.length;
    final total = _habits.length;
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(
        title: const Text('🔁 Habits'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: ThemeManager.primary,
          labelColor: ThemeManager.primary,
          unselectedLabelColor: ThemeManager.textSecondary,
          tabs: const [Tab(text: 'Today'), Tab(text: 'All Habits'), Tab(text: '📊 Heatmap')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _buildToday(done, total),
        _buildAllHabits(),
        _buildHeatmap(),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildToday(int done, int total) {
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$done of $total habits done today ${done == total && total > 0 ? '🎉' : ''}', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold)),
          Text('${total > 0 ? (done / total * 100).toInt() : 0}%', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: total > 0 ? done / total : 0, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(ThemeManager.primary), minHeight: 8),
      ]))),
      _habits.isEmpty
          ? SliverFillRemaining(child: EmptyState(icon: '🔁', title: 'No habits yet', subtitle: 'Add your first habit to start tracking!'))
          : SliverList(delegate: SliverChildBuilderDelegate((_, i) {
              final h = _habits[i];
              final isDone = _doneToday.contains(h['id'] as int);
              return _habitTile(h, isDone);
            }, childCount: _habits.length)),
    ]);
  }

  Widget _habitTile(Map<String, dynamic> h, bool isDone) {
    final streak = (h['current_streak'] as int?) ?? 0;
    return Dismissible(
      key: Key('habit_${h['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await DbHelper.instance.updateWhere('habits', {'is_archived': 1}, 'id=?', [h['id']]);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${h['name']}" archived'),
            action: SnackBarAction(label: 'Undo', onPressed: () async {
              await DbHelper.instance.updateWhere('habits', {'is_archived': 0}, 'id=?', [h['id']]);
              _load();
            }),
            duration: const Duration(seconds: 3),
          ));
        }
        return false;
      },
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: ThemeManager.warning, child: const Text('Archive', style: TextStyle(color: Colors.white))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.card,
          borderRadius: BorderRadius.circular(14),
          border: isDone ? Border.all(color: ThemeManager.primary.withAlpha(120)) : null,
        ),
        child: Row(children: [
          // Emoji icon with streak flame
          Stack(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDone ? ThemeManager.primary.withAlpha(40) : ThemeManager.surface,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(h['icon'] as String? ?? '🔁', style: const TextStyle(fontSize: 24))),
            ),
            if (streak >= 3)
              const Positioned(top: -2, right: -2, child: Text('🔥', style: TextStyle(fontSize: 14))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h['name'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('🔥 $streak day streak · Best: ${h['longest_streak']}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          ])),
          // Long press for irregular mark
          GestureDetector(
            onTap: () => _toggleHabit(h, isDone),
            onLongPress: () => _markIrregular(h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isDone ? ThemeManager.primary : ThemeManager.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDone ? ThemeManager.primary : ThemeManager.border),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAllHabits() {
    if (_habits.isEmpty) return EmptyState(icon: '🔁', title: 'No habits yet', subtitle: 'Tap + to add your first habit.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _habits.length,
      itemBuilder: (_, i) {
        final h = _habits[i];
        return Card(
          color: ThemeManager.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Text(h['icon'] as String? ?? '🔁', style: const TextStyle(fontSize: 28)),
            title: Text(h['name'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current streak: 🔥 ${h['current_streak']} days', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
              Text('Longest: ${h['longest_streak']} days  ·  Freq: ${h['frequency']}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
            ]),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEATMAP TAB (FEAT-03)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeatmap() {
    if (_habits.isEmpty) return EmptyState(icon: '📊', title: 'No habits', subtitle: 'Add habits first to see the heatmap.');

    final selectedHabit = _habits.firstWhere(
      (h) => h['id'] == _heatmapHabitId,
      orElse: () => _habits.first,
    );
    final habitId = selectedHabit['id'] as int;

    // Count irregulars this month
    final now = DateTime.now();
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    int irregularCount = 0;
    int doneCount = 0;
    int missedCount = 0;
    _heatmapData.forEach((date, statuses) {
      if (date.compareTo(monthStart) >= 0 && statuses[habitId] != null) {
        final s = statuses[habitId]!;
        if (s == 'irregular') irregularCount++;
        else if (s == 'done') doneCount++;
        else missedCount++;
      }
    });

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Habit selector
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _habits.length,
          itemBuilder: (_, i) {
            final h = _habits[i];
            final selected = h['id'] == habitId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _loadHeatmap(h['id'] as int),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? ThemeManager.primary.withAlpha(40) : ThemeManager.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? ThemeManager.primary : ThemeManager.border),
                  ),
                  child: Text('${h['icon'] ?? '🔁'} ${h['name']}', style: TextStyle(
                    color: selected ? ThemeManager.primary : ThemeManager.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  )),
                ),
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 16),

      // 5-week heatmap grid
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Last 5 Weeks', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          // Day labels
          Row(children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) =>
            Expanded(child: Center(child: Text(d, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 9, fontWeight: FontWeight.w600))))
          ).toList()),
          const SizedBox(height: 4),
          // Grid
          ...List.generate(5, (week) {
            return Row(children: List.generate(7, (dayOfWeek) {
              final daysAgo = (4 - week) * 7 + (6 - dayOfWeek);
              final date = now.subtract(Duration(days: daysAgo));
              final dateStr = date.toIso8601String().substring(0, 10);
              final status = _heatmapData[dateStr]?[habitId];

              Color cellColor;
              if (status == 'done') {
                cellColor = ThemeManager.success;
              } else if (status == 'irregular') {
                cellColor = ThemeManager.warning;
              } else if (status == 'missed') {
                cellColor = ThemeManager.danger;
              } else {
                cellColor = ThemeManager.surface2;
              }

              final isToday = dateStr == _today;

              return Expanded(child: GestureDetector(
                onLongPress: () => _editHeatmapDay(habitId, dateStr, status),
                child: Container(
                  height: 28, margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cellColor.withAlpha(status != null ? 150 : 60),
                    borderRadius: BorderRadius.circular(4),
                    border: isToday ? Border.all(color: ThemeManager.primary, width: 2) : null,
                  ),
                  child: Center(child: Text(
                    '${date.day}',
                    style: TextStyle(color: ThemeManager.textColor, fontSize: 9),
                  )),
                ),
              ));
            }));
          }),
        ]),
      ),

      const SizedBox(height: 12),

      // Legend
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendDot(ThemeManager.success, 'Done'),
        const SizedBox(width: 12),
        _legendDot(ThemeManager.warning, 'Irregular'),
        const SizedBox(width: 12),
        _legendDot(ThemeManager.danger, 'Missed'),
        const SizedBox(width: 12),
        _legendDot(ThemeManager.surface2, 'No data'),
      ]),

      // Month stats
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This Month', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _monthStat('🟩', '$doneCount', 'Done'),
            _monthStat('🟨', '$irregularCount', 'Irregular'),
            _monthStat('🟥', '$missedCount', 'Missed'),
          ]),
        ]),
      ),

      const SizedBox(height: 8),
      Text('💡 Long-press a day to mark as irregular', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
    ]));
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withAlpha(150), borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
    ]);
  }

  Widget _monthStat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      Text(value, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
    ]);
  }

  Future<void> _editHeatmapDay(int habitId, String date, String? currentStatus) async {
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeManager.card,
        title: Text('Edit: $date', style: TextStyle(color: ThemeManager.textColor)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Current: ${currentStatus ?? "not logged"}', style: TextStyle(color: ThemeManager.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(hintText: 'Note (e.g. "Did it late")…'),
            style: TextStyle(color: ThemeManager.textColor),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark as irregular
              final note = '[irregular] ${noteCtrl.text.trim()}';
              // Check if log exists
              final existing = await DbHelper.instance.fetchOne(
                'SELECT id FROM habit_logs WHERE habit_id=? AND date=?', [habitId, date]);
              if (existing != null) {
                await DbHelper.instance.updateWhere('habit_logs', {'is_done': 1, 'note': note}, 'id=?', [existing['id']]);
              } else {
                await DbHelper.instance.insert('habit_logs', {'habit_id': habitId, 'date': date, 'is_done': 1, 'note': note});
              }
              Navigator.pop(ctx);
              _loadHeatmap(habitId);
              _showSnack('🟨 Marked as irregular');
            },
            child: Text('Mark Irregular', style: TextStyle(color: ThemeManager.warning)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXISTING METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _toggleHabit(Map<String, dynamic> h, bool isDone) async {
    HapticFeedback.mediumImpact();
    if (!isDone) {
      await DbHelper.instance.insert('habit_logs', {'habit_id': h['id'], 'date': _today, 'is_done': 1});
      // Update streak
      final newStreak = (h['current_streak'] as int? ?? 0) + 1;
      final longest = newStreak > (h['longest_streak'] as int? ?? 0) ? newStreak : (h['longest_streak'] as int? ?? 0);
      await DbHelper.instance.updateWhere('habits', {'current_streak': newStreak, 'longest_streak': longest}, 'id=?', [h['id']]);
      final newBadges = await DbHelper.instance.awardXp(5, 'habit_checkin');
      if (mounted && newBadges.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('🏅 Badge unlocked!'), backgroundColor: ThemeManager.primary));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('+5 XP ⭐'), backgroundColor: ThemeManager.primary, duration: const Duration(milliseconds: 800)));
      }
    }
    await _load();
  }

  Future<void> _markIrregular(Map<String, dynamic> h) async {
    HapticFeedback.lightImpact();
    if (_doneToday.contains(h['id'] as int)) return; // already done
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeManager.card,
        title: Text('Mark as Irregular?', style: TextStyle(color: ThemeManager.textColor)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Did it late, partially, or inconsistently?', style: TextStyle(color: ThemeManager.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(hintText: 'Note (e.g. "Missed morning, did at night")'),
            style: TextStyle(color: ThemeManager.textColor),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.warning),
            onPressed: () async {
              final note = '[irregular] ${noteCtrl.text.trim()}';
              await DbHelper.instance.insert('habit_logs', {'habit_id': h['id'], 'date': _today, 'is_done': 1, 'note': note});
              final newStreak = (h['current_streak'] as int? ?? 0) + 1;
              final longest = newStreak > (h['longest_streak'] as int? ?? 0) ? newStreak : (h['longest_streak'] as int? ?? 0);
              await DbHelper.instance.updateWhere('habits', {'current_streak': newStreak, 'longest_streak': longest}, 'id=?', [h['id']]);
              await DbHelper.instance.awardXp(3, 'habit_irregular');
              Navigator.pop(ctx);
              _showSnack('🟨 Marked as irregular (+3 XP)');
              _load();
            },
            child: const Text('Mark Irregular'),
          ),
        ],
      ),
    );
  }

  void _addHabit() {
    final nameCtrl = TextEditingController();
    String icon = '🔁';
    const icons = ['🔁', '📚', '💧', '🏃', '🧘', '😴', '🍎', '✍️', '🎵', '🌿', '💊', '📖'];
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Habit', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Habit name…'), style: TextStyle(color: ThemeManager.textColor)),
          const SizedBox(height: 12),
          Text('Pick an icon', style: TextStyle(color: ThemeManager.textSecondary)),
          Wrap(spacing: 8, children: icons.map((ic) => GestureDetector(
            onTap: () => setS(() => icon = ic),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: icon == ic ? ThemeManager.primary.withAlpha(50) : ThemeManager.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: icon == ic ? ThemeManager.primary : ThemeManager.border),
              ),
              child: Text(ic, style: const TextStyle(fontSize: 22)),
            ),
          )).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('habits', {'name': nameCtrl.text.trim(), 'icon': icon, 'frequency': 'daily'});
              Navigator.pop(context); _load();
            },
            child: const Text('Add Habit'),
          )),
        ])),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }
}
