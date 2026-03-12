import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';

/// Handles WiFi sync between mobile and desktop
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  String? _serverIp;
  int _serverPort = 8765;
  bool _syncing = false;

  String? get serverIp => _serverIp;
  bool get isSyncing => _syncing;
  String get serverUrl => 'http://$_serverIp:$_serverPort';

  // Tables to sync
  static const syncTables = [
    'profiles', 'todos', 'habits', 'habit_logs', 'goals', 'milestones',
    'attendance', 'attendance_logs', 'notes', 'countdowns',
    'pomodoro_sessions', 'health_logs', 'flashcard_decks', 'flashcards',
    'flashcard_reviews', 'badges',
  ];

  /// Set the desktop server IP
  void setServer(String ip, {int port = 8765}) {
    _serverIp = ip;
    _serverPort = port;
  }

  /// Ping the server to check connection
  Future<bool> ping() async {
    if (_serverIp == null) return false;
    try {
      final resp = await http.get(Uri.parse('$serverUrl/ping')).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['app'] == 'StudentTrackPro';
      }
    } catch (_) {}
    return false;
  }

  /// Pull data from desktop → mobile
  Future<SyncResult> pullFromDesktop() async {
    if (_serverIp == null) return SyncResult(success: false, message: 'No server configured');
    _syncing = true;
    try {
      final resp = await http.get(Uri.parse('$serverUrl/export')).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return SyncResult(success: false, message: 'Server error: ${resp.statusCode}');

      final data = jsonDecode(resp.body);
      if (data['status'] != 'ok') return SyncResult(success: false, message: data['error'] ?? 'Unknown error');

      final tables = data['tables'] as Map<String, dynamic>;
      int imported = 0, updated = 0, skipped = 0;

      for (final entry in tables.entries) {
        final tableName = entry.key;
        final rows = entry.value as List<dynamic>;
        if (!syncTables.contains(tableName) || rows.isEmpty) continue;

        for (final row in rows) {
          final rowMap = Map<String, dynamic>.from(row as Map);
          final id = rowMap['id'];
          if (id == null) continue;

          // Check if exists locally
          final existing = await DbHelper.instance.fetchOne('SELECT * FROM $tableName WHERE id=?', [id]);
          if (existing == null) {
            // Insert new
            try {
              await DbHelper.instance.insert(tableName, rowMap);
              imported++;
            } catch (_) { skipped++; }
          } else {
            // Compare timestamps
            final desktopTs = (rowMap['updated_at'] ?? rowMap['created_at'] ?? '') as String;
            final localTs = (existing['updated_at'] ?? existing['created_at'] ?? '') as String;
            if (desktopTs.compareTo(localTs) > 0) {
              // Desktop is newer
              final setMap = Map<String, dynamic>.from(rowMap)..remove('id');
              try {
                await DbHelper.instance.updateWhere(tableName, setMap, 'id=?', [id]);
                updated++;
              } catch (_) { skipped++; }
            } else {
              skipped++;
            }
          }
        }
      }

      return SyncResult(success: true, message: '↓ Pulled: $imported new, $updated updated, $skipped unchanged');
    } catch (e) {
      return SyncResult(success: false, message: 'Pull failed: $e');
    } finally {
      _syncing = false;
    }
  }

  /// Push data from mobile → desktop
  Future<SyncResult> pushToDesktop() async {
    if (_serverIp == null) return SyncResult(success: false, message: 'No server configured');
    _syncing = true;
    try {
      // Export all local tables
      final allTables = <String, dynamic>{};
      for (final table in syncTables) {
        try {
          final rows = await DbHelper.instance.fetchAll('SELECT * FROM $table');
          allTables[table] = rows;
        } catch (_) {
          allTables[table] = [];
        }
      }

      final body = jsonEncode({'tables': allTables});
      final resp = await http.post(
        Uri.parse('$serverUrl/import'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) return SyncResult(success: false, message: 'Server error: ${resp.statusCode}');

      final data = jsonDecode(resp.body);
      if (data['status'] != 'ok') return SyncResult(success: false, message: data['error'] ?? 'Unknown error');

      final stats = data['stats'] as Map<String, dynamic>;
      return SyncResult(
        success: true,
        message: '↑ Pushed: ${stats['inserted']} new, ${stats['updated']} updated, ${stats['skipped']} unchanged',
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Push failed: $e');
    } finally {
      _syncing = false;
    }
  }

  /// Full bidirectional sync: push then pull
  Future<SyncResult> fullSync() async {
    final push = await pushToDesktop();
    if (!push.success) return push;
    final pull = await pullFromDesktop();
    return SyncResult(
      success: pull.success,
      message: '${push.message}\n${pull.message}',
    );
  }
}

class SyncResult {
  final bool success;
  final String message;
  SyncResult({required this.success, required this.message});
}
