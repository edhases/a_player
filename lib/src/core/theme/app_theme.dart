import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (Poweramp inspired)
  static const Color primaryColor = Color(0xFFFF6B00);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF1E1E1E);

  static ThemeData create({
    required bool isDark,
    bool amoled = false,
    int? accentColor,
  }) {
    // Default seed or user selected
    final seed =
        accentColor != null ? Color(accentColor) : const Color(0xFFFF6B00);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    // Background colors
    final bgColor = isDark
        ? (amoled ? Colors.black : const Color(0xFF121212))
        : const Color(0xFFF7F2FA); // Standard M3 light bg

    final surfaceColor = isDark
        ? (amoled ? Colors.black : const Color(0xFF1E1E1E))
        : Colors.white;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final baseTextTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      textTheme: GoogleFonts.interTextTheme(baseTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      // Keep default FAB behavior or override
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }
}
