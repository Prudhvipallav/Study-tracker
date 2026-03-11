import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'studenttrack.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Note: do NOT set PRAGMA journal_mode=WAL here — onCreate runs
        // inside a transaction and SQLite forbids changing journal mode
        // in a transaction. sqflite uses WAL by default on Android.
        for (final sql in _allTables) {
          await db.execute(sql);
        }
      },
    );
  }

  static const List<String> _allTables = [
    '''CREATE TABLE IF NOT EXISTS profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      avatar TEXT DEFAULT 'grad',
      stream TEXT NOT NULL,
      stream_locked INTEGER DEFAULT 1,
      theme TEXT NOT NULL,
      xp INTEGER DEFAULT 0,
      level INTEGER DEFAULT 1,
      dark_mode INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      priority TEXT DEFAULT 'medium',
      tags TEXT,
      due_date TEXT,
      goal_id INTEGER,
      is_completed INTEGER DEFAULT 0,
      completed_at TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS habits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      frequency TEXT DEFAULT 'daily',
      custom_days TEXT,
      color TEXT,
      icon TEXT,
      current_streak INTEGER DEFAULT 0,
      longest_streak INTEGER DEFAULT 0,
      is_archived INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS habit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER,
      date TEXT NOT NULL,
      is_done INTEGER DEFAULT 0,
      note TEXT,
      FOREIGN KEY (habit_id) REFERENCES habits(id)
    )''',
    '''CREATE TABLE IF NOT EXISTS goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      category TEXT,
      start_date TEXT,
      deadline TEXT,
      progress_percent INTEGER DEFAULT 0,
      is_completed INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS milestones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      goal_id INTEGER,
      title TEXT NOT NULL,
      deadline TEXT,
      is_completed INTEGER DEFAULT 0,
      order_index INTEGER DEFAULT 0,
      FOREIGN KEY (goal_id) REFERENCES goals(id)
    )''',
    '''CREATE TABLE IF NOT EXISTS subtasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      milestone_id INTEGER,
      title TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0,
      FOREIGN KEY (milestone_id) REFERENCES milestones(id)
    )''',
    '''CREATE TABLE IF NOT EXISTS countdowns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      exam_date TEXT NOT NULL,
      subject TEXT,
      notes TEXT,
      color TEXT,
      is_archived INTEGER DEFAULT 0
    )''',
    '''CREATE TABLE IF NOT EXISTS pomodoro_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject TEXT,
      work_duration INTEGER DEFAULT 25,
      break_duration INTEGER DEFAULT 5,
      cycles_completed INTEGER DEFAULT 0,
      total_focus_minutes INTEGER DEFAULT 0,
      date TEXT DEFAULT CURRENT_DATE
    )''',
    '''CREATE TABLE IF NOT EXISTS notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT,
      tags TEXT,
      subject TEXT,
      is_pinned INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS flashcard_decks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      subject TEXT,
      color TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS flashcards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      deck_id INTEGER,
      question TEXT NOT NULL,
      answer TEXT NOT NULL,
      difficulty TEXT DEFAULT 'medium',
      last_reviewed TEXT,
      times_correct INTEGER DEFAULT 0,
      times_wrong INTEGER DEFAULT 0,
      FOREIGN KEY (deck_id) REFERENCES flashcard_decks(id)
    )''',
    '''CREATE TABLE IF NOT EXISTS attendance (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject TEXT NOT NULL,
      total_classes INTEGER DEFAULT 0,
      attended INTEGER DEFAULT 0,
      required_percent INTEGER DEFAULT 75
    )''',
    '''CREATE TABLE IF NOT EXISTS attendance_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      attendance_id INTEGER,
      date TEXT NOT NULL,
      status TEXT NOT NULL,
      note TEXT,
      FOREIGN KEY (attendance_id) REFERENCES attendance(id)
    )''',
    '''CREATE TABLE IF NOT EXISTS health_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT DEFAULT CURRENT_DATE,
      sleep_time TEXT,
      wake_time TEXT,
      sleep_hours REAL,
      water_glasses INTEGER DEFAULT 0,
      water_goal INTEGER DEFAULT 8,
      mood INTEGER,
      mood_note TEXT,
      exercise_minutes INTEGER DEFAULT 0,
      exercise_type TEXT,
      steps INTEGER DEFAULT 0
    )''',
    '''CREATE TABLE IF NOT EXISTS xp_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount INTEGER NOT NULL,
      reason TEXT,
      earned_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS badges (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      badge_key TEXT NOT NULL UNIQUE,
      badge_name TEXT NOT NULL,
      badge_icon TEXT,
      earned_at TEXT DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS app_opens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL UNIQUE
    )''',
  ];

  // ── Generic CRUD ──────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateWhere(String table, Map<String, dynamic> data,
      String where, List<dynamic> args) async {
    final db = await database;
    return db.update(table, data, where: where, whereArgs: args);
  }

  Future<int> deleteWhere(
      String table, String where, List<dynamic> args) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: args);
  }

  Future<List<Map<String, dynamic>>> fetchAll(String query,
      [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(query, args);
  }

  Future<Map<String, dynamic>?> fetchOne(String query,
      [List<dynamic>? args]) async {
    final db = await database;
    final rows = await db.rawQuery(query, args);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> execute(String sql, [List<dynamic>? args]) async {
    final db = await database;
    await db.execute(sql, args);
  }

  // ── XP & Level ───────────────────────────────────────────────────────────

  Future<List<String>> awardXp(int amount, String reason) async {
    final db = await database;
    await db.insert('xp_logs', {
      'amount': amount,
      'reason': reason,
      'earned_at': DateTime.now().toIso8601String(),
    });
    final row = await fetchOne('SELECT xp, level FROM profiles LIMIT 1');
    if (row == null) return [];
    int xp = (row['xp'] as int) + amount;
    int level = xp ~/ 500 + 1;
    await db.update('profiles', {'xp': xp, 'level': level},
        where: 'id = (SELECT id FROM profiles LIMIT 1)');
    return await checkAndAwardBadges();
  }

  Future<double> getHabitCompletionRate(int habitId, int days) async {
    final rows = await fetchAll(
      'SELECT COUNT(*) as c FROM habit_logs WHERE habit_id=? AND is_done=1 AND date>=?',
      [habitId, DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10)],
    );
    final done = (rows.first['c'] as int?) ?? 0;
    return done / days;
  }

  Future<Map<String, dynamic>?> getTodayHealthLog() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    var row = await fetchOne('SELECT * FROM health_logs WHERE date=?', [today]);
    if (row == null) {
      await insert('health_logs', {'date': today});
      row = await fetchOne('SELECT * FROM health_logs WHERE date=?', [today]);
    }
    return row;
  }

  // ── Badge System ──────────────────────────────────────────────────────────

  Future<List<String>> checkAndAwardBadges() async {
    final newBadges = <String>[];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Track app open
    await insert('app_opens', {'date': today});

    // Helper to award
    Future<bool> award(String key, String name, String icon) async {
      final existing = await fetchOne('SELECT id FROM badges WHERE badge_key=?', [key]);
      if (existing != null) return false;
      await insert('badges', {
        'badge_key': key,
        'badge_name': name,
        'badge_icon': icon,
        'earned_at': DateTime.now().toIso8601String(),
      });
      newBadges.add(key);
      return true;
    }

    // first_task
    final tasks = await fetchOne('SELECT COUNT(*) as c FROM todos WHERE is_completed=1');
    if ((tasks?['c'] as int? ?? 0) >= 1) await award('first_task', 'First Task Done!', '✅');
    if ((tasks?['c'] as int? ?? 0) >= 50) await award('task_machine', 'Task Machine', '⚡');

    // habit streaks
    final habits = await fetchAll('SELECT current_streak FROM habits WHERE is_archived=0');
    final maxStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h['current_streak'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
    if (maxStreak >= 3) await award('streak_3', '3-Day Streak', '🔥');
    if (maxStreak >= 7) await award('streak_7', 'Week Warrior', '🏅');
    if (maxStreak >= 30) await award('streak_30', 'Unstoppable', '💎');

    // goals
    final goals = await fetchOne('SELECT COUNT(*) as c FROM goals');
    if ((goals?['c'] as int? ?? 0) >= 1) await award('first_goal', 'Goal Setter', '🎯');
    final doneGoals = await fetchOne('SELECT COUNT(*) as c FROM goals WHERE is_completed=1');
    if ((doneGoals?['c'] as int? ?? 0) >= 1) await award('goal_crusher', 'Goal Crusher', '🏆');

    // milestones
    final milestones = await fetchOne('SELECT COUNT(*) as c FROM milestones WHERE is_completed=1');
    if ((milestones?['c'] as int? ?? 0) >= 10) await award('milestone_master', 'Milestone Master', '⭐');

    // pomodoros
    final pomTotal = await fetchOne('SELECT SUM(cycles_completed) as s FROM pomodoro_sessions');
    final pomCount = (pomTotal?['s'] as int? ?? 0);
    if (pomCount >= 10) await award('pomodoro_10', 'Focus Machine', '🍅');
    if (pomCount >= 50) await award('pomodoro_50', 'Pomodoro Master', '🎖️');

    // notes
    final notes = await fetchOne('SELECT COUNT(*) as c FROM notes');
    if ((notes?['c'] as int? ?? 0) >= 10) await award('note_taker', 'Note Taker', '📝');

    // flashcards
    final decks = await fetchOne('SELECT COUNT(*) as c FROM flashcard_decks');
    if ((decks?['c'] as int? ?? 0) >= 5) await award('deck_creator', 'Knowledge Seeker', '🃏');
    final reviewed = await fetchOne(
        'SELECT SUM(times_correct + times_wrong) as s FROM flashcards');
    if (((reviewed?['s'] as int?) ?? 0) >= 100) {
      await award('flashcard_master', 'Flashcard Master', '🧠');
    }

    // levels
    final prof = await fetchOne('SELECT level FROM profiles LIMIT 1');
    final level = (prof?['level'] as int?) ?? 1;
    if (level >= 5) await award('level_5', 'Rising Star', '⭐');
    if (level >= 10) await award('level_10', 'Legend', '👑');

    // attendance
    final attRows = await fetchAll('SELECT * FROM attendance');
    for (final a in attRows) {
      final total = (a['total_classes'] as int?) ?? 0;
      final attended = (a['attended'] as int?) ?? 0;
      if (total > 20 && attended == total) {
        await award('attendance_perfect', 'Perfect Attendance', '🎓');
        break;
      }
    }

    // health streak
    final healthRows = await fetchAll(
      'SELECT date FROM health_logs WHERE sleep_hours IS NOT NULL AND water_glasses > 0 AND mood IS NOT NULL AND exercise_minutes > 0 ORDER BY date DESC LIMIT 7',
    );
    if (healthRows.length >= 7) await award('health_week', 'Health Champion', '❤️');

    // hydrated: water goal 7 days
    final waterRows = await fetchAll(
      'SELECT date FROM health_logs WHERE water_glasses >= water_goal ORDER BY date DESC LIMIT 7',
    );
    if (waterRows.length >= 7) await award('hydrated', 'Hydration Hero', '💧');

    // athlete: exercise 7 days
    final exRows = await fetchAll(
      'SELECT date FROM health_logs WHERE exercise_minutes > 0 ORDER BY date DESC LIMIT 7',
    );
    if (exRows.length >= 7) await award('athlete', 'Athlete', '🏃');

    // early bird: sleep before midnight 5 times
    final earlyRows = await fetchAll(
      "SELECT date FROM health_logs WHERE sleep_time IS NOT NULL AND sleep_time <= '23:59' ORDER BY date DESC LIMIT 5",
    );
    if (earlyRows.length >= 5) await award('early_bird', 'Early Bird', '🌅');

    // night owl: after 1am
    final nightRows = await fetchAll(
      "SELECT date FROM health_logs WHERE sleep_time IS NOT NULL AND sleep_time >= '01:00' ORDER BY date DESC LIMIT 5",
    );
    if (nightRows.length >= 5) await award('night_owl', 'Night Owl', '🦉');

    // exam survivor
    final expiredCountdown = await fetchOne(
      "SELECT COUNT(*) as c FROM countdowns WHERE exam_date <= ? AND is_archived=0",
      [today],
    );
    if ((expiredCountdown?['c'] as int? ?? 0) >= 1) {
      await award('exam_survivor', 'Exam Survivor', '🎓');
    }

    // consistent: app opened 14 days
    final openDays = await fetchOne('SELECT COUNT(*) as c FROM app_opens');
    if ((openDays?['c'] as int? ?? 0) >= 14) {
      await award('consistent', 'Consistent Learner', '📅');
    }

    return newBadges;
  }
}
