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
    _loading = true;
    notifyListeners();
    _profile = await DbHelper.instance.fetchOne('SELECT * FROM profiles LIMIT 1');
    if (_profile != null) {
      await ThemeManager.loadTheme(_profile!['stream'] as String);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _profile = await DbHelper.instance.fetchOne('SELECT * FROM profiles LIMIT 1');
    notifyListeners();
  }

  Future<void> createProfile(String name, String stream, String avatar) async {
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
    await ThemeManager.loadTheme(stream);
    await refresh();
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
