import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ThemeManager {
  static Map<String, dynamic> _theme = {};
  static String _currentStream = 'engineering';

  static Future<void> loadTheme(String stream) async {
    _currentStream = stream;
    final String jsonStr =
        await rootBundle.loadString('assets/themes/$stream.json');
    _theme = json.decode(jsonStr);
  }

  static String get stream => _currentStream;

  static Color get primary => _colorFromHex(_theme['primary'] ?? '#1E90FF');
  static Color get secondary => _colorFromHex(_theme['secondary'] ?? '#00BFFF');
  static Color get accent => _colorFromHex(_theme['accent'] ?? '#FF6B35');
  static Color get background => _colorFromHex(_theme['background'] ?? '#0D1117');
  static Color get surface => _colorFromHex(_theme['surface'] ?? '#161B22');
  static Color get surface2 => _colorFromHex(_theme['surface2'] ?? '#21262D');
  static Color get textColor => _colorFromHex(_theme['text'] ?? '#E6EDF3');
  static Color get textSecondary => _colorFromHex(_theme['text_secondary'] ?? '#8B949E');
  static Color get success => _colorFromHex(_theme['success'] ?? '#3FB950');
  static Color get warning => _colorFromHex(_theme['warning'] ?? '#D29922');
  static Color get danger => _colorFromHex(_theme['danger'] ?? '#F85149');
  static Color get card => _colorFromHex(_theme['card'] ?? '#1C2128');
  static Color get border => _colorFromHex(_theme['border'] ?? '#30363D');
  static Color get highlight => _colorFromHex(_theme['highlight'] ?? '#388BFD');

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  static Map<String, dynamic> get raw => _theme;
}
