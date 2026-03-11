import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../services/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _startPause() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
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
          } else {
            setState(() { _isWork = true; _timeLeft = _workMin * 60; _isRunning = false; });
          }
        }
      });
    }
  }

  void _reset() { _timer?.cancel(); setState(() { _isRunning = false; _isWork = true; _timeLeft = _workMin * 60; }); }

  String _timeStr() {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = (_isWork ? _workMin : _breakMin) * 60;
    final progress = 1 - _timeLeft / total;
    final color = _isWork ? ThemeManager.primary : ThemeManager.success;

    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('🍅 Focus Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(
            decoration: InputDecoration(hintText: 'Subject…', prefixIcon: Icon(Icons.book_outlined, color: ThemeManager.textSecondary)),
            style: TextStyle(color: ThemeManager.textColor),
            onChanged: (v) => _subject = v,
            controller: TextEditingController(text: _subject),
          ),
          const SizedBox(height: 40),
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 32),
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
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)],
                ),
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(onPressed: () => setState(() { _timer?.cancel(); _isRunning = false; _isWork = !_isWork; _timeLeft = (_isWork ? _workMin : _breakMin) * 60; }), icon: Icon(Icons.skip_next, color: ThemeManager.textSecondary, size: 32)),
          ]),
          const SizedBox(height: 32),
          // Settings row
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
        ]),
      ),
    );
  }
}
