import 'package:flutter/material.dart';
import 'theme_manager.dart';

class AppTheme {
  static ThemeData build({bool dark = true}) {
    final bg = ThemeManager.background;
    final surf = ThemeManager.surface;
    final primary = ThemeManager.primary;
    final text = ThemeManager.textColor;
    final border = ThemeManager.border;

    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: ThemeManager.card,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: ThemeManager.secondary,
        surface: surf,
        error: ThemeManager.danger,
        onPrimary: Colors.white,
        onSurface: text,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: ThemeManager.textSecondary),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surf,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: primary,
        unselectedItemColor: ThemeManager.textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: ThemeManager.textSecondary),
        hintStyle: TextStyle(color: ThemeManager.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ThemeManager.surface2,
        labelStyle: TextStyle(color: text, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: border,
      iconTheme: IconThemeData(color: ThemeManager.textSecondary),
      useMaterial3: true,
    );
  }
}
