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
  List<Map<String, dynamic>> _weekLogs = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final log = await DbHelper.instance.getTodayHealthLog();
    final week = await DbHelper.instance.getWeekHealthLogs();
    if (mounted) setState(() { _log = log; _weekLogs = week; });
  }

  Future<void> _save(Map<String, dynamic> data) async {
    if (_log?['id'] == null) return;
    await DbHelper.instance.updateWhere('health_logs', data, 'id=?', [_log!['id']]);
    await _load();
  }

  void _showSaved(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeManager.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SLEEP TAB (BUG-03)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSleep() {
    final sleep = (_log?['sleep_hours'] as num?)?.toDouble() ?? 0;
    final bedtime = _log?['sleep_time'] as String?;
    final waketime = _log?['wake_time'] as String?;
    final sleepQuality = sleep >= 8 ? 'Excellent 🌟' : sleep >= 7 ? 'Good 😊' : sleep >= 6 ? 'Fair 😐' : sleep > 0 ? 'Poor 😴' : 'Not logged';

    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Sleep Tracker'),

      // Current sleep display
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(sleep > 0 ? '${sleep.toStringAsFixed(1)} hrs' : '— hrs',
              style: TextStyle(color: ThemeManager.textColor, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sleepQuality, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 14)),

          const SizedBox(height: 20),

          // Bedtime picker
          Row(children: [
            Expanded(child: _timePickerTile(
              icon: Icons.bedtime,
              label: 'Bedtime',
              value: bedtime ?? 'Set time',
              onTap: () => _pickTime('sleep_time', bedtime),
            )),
            const SizedBox(width: 12),
            Expanded(child: _timePickerTile(
              icon: Icons.wb_sunny,
              label: 'Wake Time',
              value: waketime ?? 'Set time',
              onTap: () => _pickTime('wake_time', waketime),
            )),
          ]),

          const SizedBox(height: 16),

          // Manual slider fallback
          Text('Or set hours manually:', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          Slider(
            value: sleep,
            min: 0, max: 12, divisions: 24,
            activeColor: ThemeManager.primary,
            label: '${sleep.toStringAsFixed(1)} hrs',
            onChanged: (v) => setState(() => _log!['sleep_hours'] = v),
            onChangeEnd: (v) async {
              await _save({'sleep_hours': v});
              await DbHelper.instance.awardXp(3, 'log_sleep');
              _showSaved('✅ Sleep logged: ${v.toStringAsFixed(1)} hrs');
            },
          ),

          // Visual bar
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _sleepBar('😴', sleep, 12),
            Column(children: [
              Icon(Icons.bedtime, color: ThemeManager.primary, size: 32),
              Text('Recommended\n7–9 hrs', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11), textAlign: TextAlign.center),
            ]),
          ]),
        ]),
      ),

      // 7-day history
      const SizedBox(height: 20),
      const SectionHeader(title: '📊 7-Day Sleep History'),
      _weekLogs.isEmpty
          ? _emptyHistory('No sleep data yet')
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weekLogs.map((log) {
                  final hrs = (log['sleep_hours'] as num?)?.toDouble() ?? 0;
                  final date = log['date'] as String? ?? '';
                  final day = date.length >= 10 ? _shortDay(date) : '?';
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${hrs.toStringAsFixed(0)}h', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28, height: (hrs / 12 * 80).clamp(4, 80),
                      decoration: BoxDecoration(
                        color: hrs >= 7 ? ThemeManager.success : hrs >= 5 ? ThemeManager.warning : ThemeManager.danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(day, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
                  ]);
                }).toList(),
              ),
            ),
    ]));
  }

  Widget _timePickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: ThemeManager.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeManager.border),
        ),
        child: Row(children: [
          Icon(icon, color: ThemeManager.primary, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
            Text(value, style: TextStyle(color: ThemeManager.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _pickTime(String field, String? current) async {
    TimeOfDay initial = const TimeOfDay(hour: 22, minute: 0);
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts[1]) ?? 0);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _save({field: timeStr});

    // Auto-calculate sleep hours if both times are set
    final updatedLog = _log!;
    final bedStr = updatedLog['sleep_time'] as String?;
    final wakeStr = updatedLog['wake_time'] as String?;
    if (bedStr != null && wakeStr != null && bedStr.contains(':') && wakeStr.contains(':')) {
      final bedParts = bedStr.split(':');
      final wakeParts = wakeStr.split(':');
      final bedMinutes = int.parse(bedParts[0]) * 60 + int.parse(bedParts[1]);
      final wakeMinutes = int.parse(wakeParts[0]) * 60 + int.parse(wakeParts[1]);
      var diff = wakeMinutes - bedMinutes;
      if (diff < 0) diff += 24 * 60; // overnight
      final hours = diff / 60.0;
      await _save({'sleep_hours': hours});
      await DbHelper.instance.awardXp(3, 'log_sleep');
      _showSaved('✅ Sleep: ${hours.toStringAsFixed(1)} hrs ($bedStr → $wakeStr)');
    }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // WATER TAB (BUG-04)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWater() {
    final glasses = (_log?['water_glasses'] as int?) ?? 0;
    final goal = (_log?['water_goal'] as int?) ?? 8;
    final reachedGoal = glasses >= goal;

    // Count streak days
    int streak = 0;
    for (int i = _weekLogs.length - 1; i >= 0; i--) {
      final g = (_weekLogs[i]['water_glasses'] as int?) ?? 0;
      final wg = (_weekLogs[i]['water_goal'] as int?) ?? 8;
      if (g >= wg) { streak++; } else { break; }
    }

    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SectionHeader(title: 'Water Intake'),

      // Main display
      Text('$glasses / $goal glasses', style: TextStyle(
        color: reachedGoal ? ThemeManager.success : ThemeManager.textColor,
        fontSize: 28, fontWeight: FontWeight.bold,
      )),
      if (reachedGoal) ...[
        const SizedBox(height: 4),
        Text('🎉 Daily goal reached!', style: TextStyle(color: ThemeManager.success, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
      const SizedBox(height: 4),

      // Streak display
      if (streak > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ThemeManager.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('🔥 $streak-day hydration streak!', style: TextStyle(color: ThemeManager.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),

      const SizedBox(height: 12),
      _waterBottle(glasses, goal),
      const SizedBox(height: 20),

      // Buttons
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton.icon(
          onPressed: () async {
            if (glasses < 20) {
              await _save({'water_glasses': glasses + 1});
              await DbHelper.instance.awardXp(3, 'log_water');
              if (glasses + 1 >= goal) {
                _showSaved('🎉 Water goal reached! ($goal glasses)');
              } else {
                _showSaved('💧 Glass ${glasses + 1} / $goal logged');
              }
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Glass'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () async {
            if (glasses > 0) {
              await _save({'water_glasses': glasses - 1});
            }
          },
          child: const Text('−1'),
        ),
        const SizedBox(width: 12),
        // Set goal button
        OutlinedButton.icon(
          onPressed: _showGoalDialog,
          icon: const Icon(Icons.flag, size: 18),
          label: const Text('Goal'),
        ),
      ]),

      const SizedBox(height: 16),
      // Glass icons
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(goal, (i) =>
        Icon(i < glasses ? Icons.local_drink : Icons.local_drink_outlined,
          color: i < glasses ? ThemeManager.primary : ThemeManager.border, size: 32),
      )),

      // 7-day water history
      const SizedBox(height: 20),
      const SectionHeader(title: '📊 7-Day Water History'),
      _weekLogs.isEmpty
          ? _emptyHistory('No water data yet')
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weekLogs.map((log) {
                  final g = (log['water_glasses'] as int?) ?? 0;
                  final wg = (log['water_goal'] as int?) ?? 8;
                  final date = log['date'] as String? ?? '';
                  final day = date.length >= 10 ? _shortDay(date) : '?';
                  final hit = g >= wg;
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$g', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28, height: (g / 20 * 80).clamp(4, 80),
                      decoration: BoxDecoration(
                        color: hit ? ThemeManager.success : ThemeManager.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(day, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
                  ]);
                }).toList(),
              ),
            ),
    ]));
  }

  Future<void> _showGoalDialog() async {
    int newGoal = (_log?['water_goal'] as int?) ?? 8;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: ThemeManager.card,
        title: Text('Set Daily Water Goal', style: TextStyle(color: ThemeManager.textColor)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$newGoal glasses', style: TextStyle(color: ThemeManager.primary, fontSize: 28, fontWeight: FontWeight.bold)),
          Slider(
            value: newGoal.toDouble(), min: 1, max: 20, divisions: 19,
            activeColor: ThemeManager.primary,
            label: '$newGoal',
            onChanged: (v) => setDialogState(() => newGoal = v.toInt()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _save({'water_goal': newGoal});
              if (mounted) Navigator.pop(ctx);
              _showSaved('🎯 Water goal set to $newGoal glasses');
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
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
              color: ThemeManager.primary.withAlpha(100),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
          ),
        ),
        Center(child: Text('${(frac * 100).toInt()}%', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold))),
      ]),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOOD TAB (BUG-02)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMood() {
    final mood = (_log?['mood'] as int?);
    final moodNote = (_log?['mood_note'] as String?) ?? '';
    final noteController = TextEditingController(text: moodNote);
    final moods = ['😞', '😕', '😐', '😊', '😄'];
    final moodLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Great'];

    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SectionHeader(title: "Today's Mood"),

      // Saved mood display
      if (mood != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: ThemeManager.success.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeManager.success.withAlpha(80)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text("Today's mood saved: ${moods[mood - 1]} ${moodLabels[mood - 1]}",
                style: TextStyle(color: ThemeManager.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),

      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(mood != null ? 'Change your mood?' : 'How are you feeling today?',
              style: TextStyle(color: ThemeManager.textColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),

          MoodPicker(selected: mood, onSelect: (m) async {
            await _save({'mood': m});
            await DbHelper.instance.awardXp(3, 'log_mood');
            _showSaved('✅ Mood saved: ${moods[m - 1]} ${moodLabels[m - 1]}');
          }),

          const SizedBox(height: 20),

          // Note field with save
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Add a note about your mood… (optional)',
              suffixIcon: IconButton(
                icon: Icon(Icons.save, color: ThemeManager.primary),
                onPressed: () async {
                  await _save({'mood_note': noteController.text});
                  _showSaved('📝 Mood note saved');
                },
              ),
            ),
            onSubmitted: (v) async {
              await _save({'mood_note': v});
              _showSaved('📝 Mood note saved');
            },
          ),
        ]),
      ),

      // 7-day mood history
      const SizedBox(height: 20),
      const SectionHeader(title: '📊 7-Day Mood History'),
      _weekLogs.isEmpty
          ? _emptyHistory('No mood data yet')
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _weekLogs.map((log) {
                  final m = log['mood'] as int?;
                  final date = log['date'] as String? ?? '';
                  final day = date.length >= 10 ? _shortDay(date) : '?';
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(m != null ? moods[m - 1] : '·', style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(day, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10)),
                  ]);
                }).toList(),
              ),
            ),
    ]));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXERCISE TAB (BUG-01)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExercise() {
    final mins = (_log?['exercise_minutes'] as int?) ?? 0;
    final type = (_log?['exercise_type'] as String?) ?? '';
    final types = ['🏃 Run', '🧘 Yoga', '💪 Gym', '🚶 Walk', '🏊 Swim', '🚴 Cycle'];
    int sliderMins = mins;

    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SectionHeader(title: '🏃 Exercise Log'),

      // Today's status
      if (mins > 0)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: ThemeManager.success.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThemeManager.success.withAlpha(80)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text('Today: $mins min ${type.isNotEmpty ? "($type)" : ""}',
                style: TextStyle(color: ThemeManager.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),

      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          // Exercise type selector
          Text('What did you do?', style: TextStyle(color: ThemeManager.textColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: types.map((t) =>
            ChoiceChip(
              label: Text(t),
              selected: type == t,
              onSelected: (_) async {
                await _save({'exercise_type': t});
              },
              selectedColor: ThemeManager.success,
            )).toList(),
          ),

          const SizedBox(height: 20),

          // Duration
          Text('How long?', style: TextStyle(color: ThemeManager.textColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          StatefulBuilder(builder: (context, setSlider) => Column(children: [
            Text('$sliderMins minutes', style: TextStyle(color: ThemeManager.textColor, fontSize: 28, fontWeight: FontWeight.bold)),
            Slider(
              value: sliderMins.toDouble(), min: 0, max: 240, divisions: 48,
              activeColor: ThemeManager.success,
              label: '$sliderMins min',
              onChanged: (v) => setSlider(() => sliderMins = v.toInt()),
              onChangeEnd: (v) async {
                await _save({'exercise_minutes': v.toInt()});
                if (v > 0) {
                  await DbHelper.instance.awardXp(3, 'log_exercise');
                  _showSaved('✅ Exercise logged: ${v.toInt()} min');
                }
              },
            ),
            // Quick buttons
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final q in [15, 30, 45, 60])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () async {
                      setSlider(() => sliderMins = q);
                      await _save({'exercise_minutes': q});
                      await DbHelper.instance.awardXp(3, 'log_exercise');
                      _showSaved('✅ Exercise logged: $q min');
                    },
                    child: Text('${q}m'),
                  ),
                ),
            ]),
          ])),
        ]),
      ),

      // 7-day exercise history
      const SizedBox(height: 20),
      const SectionHeader(title: '📊 7-Day Exercise History'),
      _weekLogs.isEmpty
          ? _emptyHistory('No exercise data yet')
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: _weekLogs.map((log) {
                  final m = (log['exercise_minutes'] as int?) ?? 0;
                  final t = (log['exercise_type'] as String?) ?? '';
                  final date = log['date'] as String? ?? '';
                  final day = date.length >= 10 ? _shortDay(date) : '?';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(width: 32, child: Text(day, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (m / 120).clamp(0, 1),
                            backgroundColor: ThemeManager.surface2,
                            valueColor: AlwaysStoppedAnimation(m > 0 ? ThemeManager.success : ThemeManager.border),
                            minHeight: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 60, child: Text(m > 0 ? '$m min' : '—', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11))),
                    ]),
                  );
                }).toList(),
              ),
            ),
    ]));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _emptyHistory(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
      child: Text(msg, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13), textAlign: TextAlign.center),
    );
  }

  String _shortDay(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } catch (_) {
      return '?';
    }
  }
}
