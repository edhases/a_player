import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extended theme colors for player and bottom sheets.
/// Access via `Theme.of(context).extension<AppColors>()`.
class AppColors extends ThemeExtension<AppColors> {
  /// Background for bottom sheets
  final Color sheetBackground;
  
  /// Primary text on dark backgrounds
  final Color textPrimary;
  
  /// Secondary text (subtitles, hints)
  final Color textSecondary;
  
  /// Muted text (disabled, timestamps)
  final Color textMuted;
  
  /// Divider/border color
  final Color divider;
  
  /// Overlay for shadows
  final Color overlay;
  
  /// Success color (e.g., granted permissions)
  final Color success;
  
  /// Error color (e.g., denied permissions)
  final Color error;

  const AppColors({
    required this.sheetBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.overlay,
    required this.success,
    required this.error,
  });

  /// Dark theme colors
  static const dark = AppColors(
    sheetBackground: Color(0xFF1C1C1E),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textMuted: Colors.white54,
    divider: Color(0xFF3A3A3C),
    overlay: Colors.black54,
    success: Color(0xFF4CAF50),
    error: Color(0xFFF44336),
  );

  /// Light theme colors
  static const light = AppColors(
    sheetBackground: Colors.white,
    textPrimary: Colors.black,
    textSecondary: Colors.black87,
    textMuted: Colors.black54,
    divider: Color(0xFFE0E0E0),
    overlay: Colors.black26,
    success: Color(0xFF4CAF50),
    error: Color(0xFFE53935),
  );

  @override
  AppColors copyWith({
    Color? sheetBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? overlay,
    Color? success,
    Color? error,
  }) {
    return AppColors(
      sheetBackground: sheetBackground ?? this.sheetBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      overlay: overlay ?? this.overlay,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      sheetBackground: Color.lerp(sheetBackground, other.sheetBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Convenient extension to access AppColors from context.
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}

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
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      // Keep default FAB behavior or override
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Custom color extensions
      extensions: [
        isDark ? AppColors.dark : AppColors.light,
      ],
    );
  }
}
