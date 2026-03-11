import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../theme/theme_manager.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get hasProfile => _profile != null;

  ProfileProvider() {
    _load();
  }

  Future<void> _load() async {
    debugPrint('>>> ProfileProvider._load() START');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('>>> ProfileProvider: opening database...');
      _profile = await DbHelper.instance.fetchOne('SELECT * FROM profiles LIMIT 1');
      debugPrint('>>> ProfileProvider: profile fetched, hasProfile=${_profile != null}');
      if (_profile != null) {
        final stream = _profile!['stream'] as String? ?? 'engineering';
        debugPrint('>>> ProfileProvider: loading theme for $stream...');
        await ThemeManager.loadTheme(stream);
        debugPrint('>>> ProfileProvider: theme loaded');
      }
    } catch (e) {
      debugPrint('>>> ProfileProvider._load ERROR: $e');
      _profile = null;
    }
    _loading = false;
    debugPrint('>>> ProfileProvider._load() DONE — loading=false, hasProfile=$hasProfile');
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _profile = await DbHelper.instance.fetchOne('SELECT * FROM profiles LIMIT 1');
    } catch (e) {
      debugPrint('ProfileProvider.refresh error: $e');
    }
    notifyListeners();
  }

  Future<void> createProfile(String name, String stream, String avatar) async {
    debugPrint('>>> createProfile START: name=$name stream=$stream');
    await DbHelper.instance.insert('profiles', {
      'name': name,
      'stream': stream,
      'theme': stream,
      'avatar': avatar,
      'stream_locked': 1,
      'xp': 0,
      'level': 1,
      'dark_mode': 1,
    });
    debugPrint('>>> createProfile: profile inserted, loading theme...');
    await ThemeManager.loadTheme(stream);
    debugPrint('>>> createProfile: theme loaded, refreshing...');
    await refresh();
    debugPrint('>>> createProfile DONE');
  }

  Future<void> updateAvatar(String avatar) async {
    if (_profile == null) return;
    await DbHelper.instance.updateWhere('profiles', {'avatar': avatar}, 'id=?', [_profile!['id']]);
    await refresh();
  }

  Future<void> updateName(String name) async {
    if (_profile == null) return;
    await DbHelper.instance.updateWhere('profiles', {'name': name}, 'id=?', [_profile!['id']]);
    await refresh();
  }
}
