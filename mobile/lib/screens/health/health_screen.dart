import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic>? _log;

  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); _load(); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final log = await DbHelper.instance.getTodayHealthLog();
    if (mounted) setState(() => _log = log);
  }

  Future<void> _save(Map<String, dynamic> data) async {
    if (_log?['id'] == null) return;
    await DbHelper.instance.updateWhere('health_logs', data, 'id=?', [_log!['id']]);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(
        title: const Text('❤️ Health Dashboard'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: ThemeManager.primary,
          labelColor: ThemeManager.primary,
          unselectedLabelColor: ThemeManager.textSecondary,
          tabs: const [Tab(text: '😴 Sleep'), Tab(text: '💧 Water'), Tab(text: '😊 Mood'), Tab(text: '🏃 Exercise')],
        ),
      ),
      body: _log == null
          ? Center(child: CircularProgressIndicator(color: ThemeManager.primary))
          : TabBarView(controller: _tab, children: [
              _buildSleep(),
              _buildWater(),
              _buildMood(),
              _buildExercise(),
            ]),
    );
  }

  Widget _buildSleep() {
    final sleep = (_log?['sleep_hours'] as num?)?.toDouble() ?? 0;
    final sleepQuality = sleep >= 8 ? 'Excellent 🌟' : sleep >= 7 ? 'Good 😊' : sleep >= 6 ? 'Fair 😐' : 'Poor 😴';
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Sleep Tracker'),
      // Sleep hours slider
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Text('${sleep.toStringAsFixed(1)} hrs · $sleepQuality', style: TextStyle(color: ThemeManager.textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Hours slept tonight', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Slider(
          value: sleep,
          min: 0, max: 12, divisions: 24,
          activeColor: ThemeManager.primary,
          onChanged: (v) async {
            setState(() => _log!['sleep_hours'] = v);
            await _save({'sleep_hours': v});
            await DbHelper.instance.awardXp(3, 'log_sleep');
          },
        ),
        // Bar chart for visual
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _sleepBar('😴', sleep, 12),
          Column(children: [
            Icon(Icons.bedtime, color: ThemeManager.primary, size: 32),
            Text('Recommended\n7–9 hrs', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11), textAlign: TextAlign.center),
          ]),
        ]),
      ])),
    ]));
  }

  Widget _sleepBar(String icon, double val, double max) {
    return Column(children: [
      SizedBox(
        width: 60, height: 120,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          Container(width: 40, height: 120, decoration: BoxDecoration(color: ThemeManager.surface2, borderRadius: BorderRadius.circular(8))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40, height: (val / max * 120).clamp(4, 120),
            decoration: BoxDecoration(color: ThemeManager.primary, borderRadius: BorderRadius.circular(8)),
          ),
        ]),
      ),
      Text(icon, style: const TextStyle(fontSize: 20)),
    ]);
  }

  Widget _buildWater() {
    final glasses = (_log?['water_glasses'] as int?) ?? 0;
    final goal = (_log?['water_goal'] as int?) ?? 8;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      SectionHeader(title: 'Water Intake'),
      Text('$glasses / $goal glasses', style: TextStyle(color: ThemeManager.textColor, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      // Animated water bottle visualization
      _waterBottle(glasses, goal),
      const SizedBox(height: 24),
      // Glass buttons
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton.icon(
          onPressed: () async { if (glasses < 20) { await _save({'water_glasses': glasses + 1}); await DbHelper.instance.awardXp(3, 'log_water'); } },
          icon: const Icon(Icons.add),
          label: const Text('Add Glass'),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: () async { if (glasses > 0) await _save({'water_glasses': glasses - 1}); },
          child: const Text('−1'),
        ),
      ]),
      const SizedBox(height: 20),
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(goal, (i) =>
        Icon(i < glasses ? Icons.local_drink : Icons.local_drink_outlined,
          color: i < glasses ? ThemeManager.primary : ThemeManager.border, size: 32),
      )),
    ]));
  }

  Widget _waterBottle(int glasses, int goal) {
    final frac = goal > 0 ? (glasses / goal).clamp(0.0, 1.0) : 0.0;
    return Center(child: Container(
      width: 80, height: 160,
      decoration: BoxDecoration(border: Border.all(color: ThemeManager.primary, width: 2), borderRadius: const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(20))),
      child: Stack(alignment: Alignment.bottomCenter, children: [
        AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 400),
          heightFactor: frac,
          child: Container(
            decoration: BoxDecoration(
              color: ThemeManager.primary.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
          ),
        ),
        Center(child: Text('${(frac * 100).toInt()}%', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold))),
      ]),
    ));
  }

  Widget _buildMood() {
    final mood = (_log?['mood'] as int?);
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      SectionHeader(title: "Today's Mood"),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Text(mood != null ? 'How are you feeling? ${['😞','😕','😐','😊','😄'][mood-1]}' : 'How are you feeling today?',
            style: TextStyle(color: ThemeManager.textColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        MoodPicker(selected: mood, onSelect: (m) async { await _save({'mood': m}); await DbHelper.instance.awardXp(3, 'log_mood'); }),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(hintText: 'Note anything? (optional)…'),
          controller: TextEditingController(text: _log?['mood_note'] as String? ?? ''),
          onSubmitted: (v) => _save({'mood_note': v}),
        ),
      ])),
    ]));
  }

  Widget _buildExercise() {
    final mins = (_log?['exercise_minutes'] as int?) ?? 0;
    final type = (_log?['exercise_type'] as String?) ?? '';
    final types = ['🏃 Run', '🧘 Yoga', '💪 Gym', '🚶 Walk', '🏊 Swim', '🚴 Cycle'];
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      SectionHeader(title: '🏃 Exercise Log'),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Text('$mins minutes', style: TextStyle(color: ThemeManager.textColor, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Slider(
          value: mins.toDouble(), min: 0, max: 240, divisions: 48,
          activeColor: ThemeManager.success,
          onChanged: (v) async { await _save({'exercise_minutes': v.toInt()}); if (v > 0) await DbHelper.instance.awardXp(3, 'log_exercise'); },
          label: '$mins min',
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: types.map((t) =>
          ChoiceChip(
            label: Text(t),
            selected: type.contains(t.split(' ').last),
            onSelected: (_) => _save({'exercise_type': t}),
            selectedColor: ThemeManager.success,
          )).toList(),
        ),
      ])),
    ]));
  }
}
