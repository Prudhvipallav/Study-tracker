import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../services/notification_service.dart';
import '../../services/sound_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with SingleTickerProviderStateMixin {
  int _workMin = 25, _breakMin = 5;
  bool _isRunning = false, _isWork = true;
  int _timeLeft = 25 * 60;
  int _cycles = 0;
  Timer? _timer;
  String _subject = 'Study Session';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Sound & focus settings
  bool _soundEnabled = true;
  bool _tickEnabled = false;
  String _ambientSound = 'none';
  double _ambientVolume = 0.3;
  bool _focusMode = false; // screen stays on

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _disableFocusMode();
    SoundService.instance.stopAmbient();
    super.dispose();
  }

  void _enableFocusMode() {
    WakelockPlus.enable();
    setState(() => _focusMode = true);
  }

  void _disableFocusMode() {
    WakelockPlus.disable();
    setState(() => _focusMode = false);
  }

  void _startPause() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      if (_focusMode) _disableFocusMode();
      SoundService.instance.stopAmbient();
    } else {
      setState(() => _isRunning = true);
      _enableFocusMode();

      // Start ambient sound if selected
      if (_ambientSound != 'none') {
        SoundService.instance.startAmbient(_ambientSound);
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
          // Tick sound every second if enabled
          if (_tickEnabled && _soundEnabled && _timeLeft % 1 == 0) {
            SoundService.instance.playTick();
          }
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();

          // Play alarm sound
          if (_soundEnabled) {
            SoundService.instance.playAlarm();
          }

          // Stop ambient during transition
          SoundService.instance.stopAmbient();

          await NotificationService.showPomodoroComplete(_isWork);
          if (_isWork) {
            final db = DbHelper.instance;
            final today = DateTime.now().toIso8601String().substring(0, 10);
            setState(() { _cycles++; _isWork = false; _timeLeft = _breakMin * 60; _isRunning = false; });
            final existing = await db.fetchOne('SELECT id FROM pomodoro_sessions WHERE date=?', [today]);
            if (existing != null) {
              await db.execute('UPDATE pomodoro_sessions SET cycles_completed = cycles_completed + 1, total_focus_minutes = total_focus_minutes + ? WHERE date=?', [_workMin, today]);
            } else {
              await db.insert('pomodoro_sessions', {'subject': _subject, 'work_duration': _workMin, 'break_duration': _breakMin, 'cycles_completed': 1, 'total_focus_minutes': _workMin, 'date': today});
            }
            await db.awardXp(15, 'pomodoro_cycle');
            if (mounted) _showSnack('🍅 Cycle complete! +15 XP • Take a $_breakMin min break');
          } else {
            setState(() { _isWork = true; _timeLeft = _workMin * 60; _isRunning = false; });
            if (mounted) _showSnack('⏰ Break over! Ready for the next focus session?');
          }
          _disableFocusMode();
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    SoundService.instance.stopAmbient();
    _disableFocusMode();
    setState(() { _isRunning = false; _isWork = true; _timeLeft = _workMin * 60; });
  }

  String _timeStr() {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = (_isWork ? _workMin : _breakMin) * 60;
    final progress = 1 - _timeLeft / total;
    final color = _isWork ? ThemeManager.primary : ThemeManager.success;

    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(
        title: const Text('🍅 Focus Timer'),
        actions: [
          // Focus mode indicator
          if (_focusMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('🔒 Focus', style: TextStyle(fontSize: 11)),
                backgroundColor: ThemeManager.primary.withAlpha(40),
                side: BorderSide.none,
              ),
            ),
          // Sound settings
          IconButton(
            icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, color: ThemeManager.textSecondary),
            onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
            tooltip: 'Toggle sounds',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(
            decoration: InputDecoration(hintText: 'Subject…', prefixIcon: Icon(Icons.book_outlined, color: ThemeManager.textSecondary)),
            style: TextStyle(color: ThemeManager.textColor),
            onChanged: (v) => _subject = v,
            controller: TextEditingController(text: _subject),
          ),
          const SizedBox(height: 30),

          // Circular timer
          ScaleTransition(
            scale: _isRunning ? _pulse : const AlwaysStoppedAnimation(1.0),
            child: SizedBox(
              width: 240, height: 240,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 12, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(color))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_timeStr(), style: TextStyle(color: ThemeManager.textColor, fontSize: 52, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()])),
                  Text(_isWork ? 'FOCUS' : 'BREAK', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 3)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Cycle indicators
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) =>
            Container(
              width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _cycles % 4 ? ThemeManager.primary : ThemeManager.surface2,
                border: Border.all(color: i < _cycles % 4 ? ThemeManager.primary : ThemeManager.border),
              ),
            )),
          ),
          Text('$_cycles cycles complete', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: _reset, icon: Icon(Icons.replay, color: ThemeManager.textSecondary, size: 32)),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _startPause,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 20)],
                ),
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(onPressed: () => setState(() { _timer?.cancel(); _isRunning = false; SoundService.instance.stopAmbient(); _disableFocusMode(); _isWork = !_isWork; _timeLeft = (_isWork ? _workMin : _breakMin) * 60; }), icon: Icon(Icons.skip_next, color: ThemeManager.textSecondary, size: 32)),
          ]),
          const SizedBox(height: 24),

          // Duration settings
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Work:', style: TextStyle(color: ThemeManager.textSecondary)),
            IconButton(onPressed: () => setState(() { if (_workMin > 5) _workMin -= 5; if (!_isRunning) _timeLeft = _workMin * 60; }), icon: Icon(Icons.remove_circle_outline, color: ThemeManager.primary)),
            Text('$_workMin min', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => setState(() { _workMin += 5; if (!_isRunning) _timeLeft = _workMin * 60; }), icon: Icon(Icons.add_circle_outline, color: ThemeManager.primary)),
            const SizedBox(width: 16),
            Text('Break:', style: TextStyle(color: ThemeManager.textSecondary)),
            IconButton(onPressed: () => setState(() { if (_breakMin > 1) _breakMin -= 1; }), icon: Icon(Icons.remove_circle_outline, color: ThemeManager.success)),
            Text('$_breakMin min', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => setState(() => _breakMin += 1), icon: Icon(Icons.add_circle_outline, color: ThemeManager.success)),
          ]),

          const SizedBox(height: 16),
          Divider(color: ThemeManager.border),

          // ── Sound & Focus Settings ──────────────────────────────────────

          _buildSoundSettings(),
        ]),
      ),
    );
  }

  Widget _buildSoundSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🎵 Sound & Focus', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),

        // Ambient sound selector
        Text('Ambient Sound', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: SoundService.ambientSounds.keys.map((name) {
          final selected = _ambientSound == name;
          return GestureDetector(
            onTap: () {
              setState(() => _ambientSound = name);
              if (_isRunning) {
                if (name == 'none') {
                  SoundService.instance.stopAmbient();
                } else {
                  SoundService.instance.startAmbient(name);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? ThemeManager.primary.withAlpha(40) : ThemeManager.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? ThemeManager.primary : ThemeManager.border),
              ),
              child: Text(name == 'none' ? '🔇 None' : name, style: TextStyle(
                color: selected ? ThemeManager.primary : ThemeManager.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              )),
            ),
          );
        }).toList()),

        // Volume slider (only when ambient is selected)
        if (_ambientSound != 'none') ...[
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.volume_down, color: ThemeManager.textSecondary, size: 18),
            Expanded(child: Slider(
              value: _ambientVolume,
              min: 0.05, max: 1.0,
              activeColor: ThemeManager.primary,
              onChanged: (v) {
                setState(() => _ambientVolume = v);
                SoundService.instance.setAmbientVolume(v);
              },
            )),
            Icon(Icons.volume_up, color: ThemeManager.textSecondary, size: 18),
          ]),
        ],

        const SizedBox(height: 8),
        Divider(color: ThemeManager.border),
        const SizedBox(height: 8),

        // Toggle options
        _toggleRow(Icons.alarm, 'Alarm on timer end', _soundEnabled, (v) => setState(() => _soundEnabled = v)),
        _toggleRow(Icons.timer, 'Tick sound every second', _tickEnabled, (v) => setState(() => _tickEnabled = v)),
        _toggleRow(Icons.screen_lock_portrait, 'Keep screen on during focus', _focusMode, (v) {
          if (v) { _enableFocusMode(); } else { _disableFocusMode(); }
        }),
      ]),
    );
  }

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: ThemeManager.textSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(color: ThemeManager.textColor, fontSize: 13))),
        Switch(
          value: value,
          activeTrackColor: ThemeManager.primary,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
