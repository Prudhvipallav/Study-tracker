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

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final habits = await DbHelper.instance.fetchAll('SELECT * FROM habits WHERE is_archived=0 ORDER BY created_at');
    final logs = await DbHelper.instance.fetchAll('SELECT habit_id FROM habit_logs WHERE date=? AND is_done=1', [_today]);
    if (mounted) setState(() { _habits = habits; _doneToday = logs.map((l) => l['habit_id'] as int).toSet(); });
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
          tabs: const [Tab(text: 'Today'), Tab(text: 'All Habits')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _buildToday(done, total),
        _buildAllHabits(),
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
    return Dismissible(
      key: Key('habit_${h['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async { await DbHelper.instance.updateWhere('habits', {'is_archived': 1}, 'id=?', [h['id']]); _load(); },
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: ThemeManager.warning, child: const Text('Archive', style: TextStyle(color: Colors.white))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeManager.card,
          borderRadius: BorderRadius.circular(14),
          border: isDone ? Border.all(color: ThemeManager.primary.withOpacity(0.5)) : null,
        ),
        child: Row(children: [
          // Emoji icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isDone ? ThemeManager.primary.withOpacity(0.15) : ThemeManager.surface,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(h['icon'] as String? ?? '🔁', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h['name'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('🔥 ${h['current_streak']} day streak · Best: ${h['longest_streak']}', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          ])),
          GestureDetector(
            onTap: () => _toggleHabit(h, isDone),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🏅 Badge unlocked!'), backgroundColor: ThemeManager.primary));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('+5 XP ⭐'), backgroundColor: ThemeManager.primary, duration: const Duration(milliseconds: 800)));
      }
    }
    await _load();
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
                color: icon == ic ? ThemeManager.primary.withOpacity(0.2) : ThemeManager.surface,
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
}
