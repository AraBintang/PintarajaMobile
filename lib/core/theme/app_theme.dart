// ============================================================
// PINTARAJA — APP THEME
// Mobile Design System berdasarkan website original
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ==========================================================
  // BRAND
  // ==========================================================

  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF3A7BC8);
  static const Color primaryLight = Color(0xFF7AB3E8);

  static const Color accent = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);

  // ==========================================================
  // LIGHT
  // ==========================================================

  static const Color backgroundLight = Color(0xFFF0F2F5);
  static const Color backgroundApp = Color(0xFFF8FAFC);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color inputLight = Color(0xFFF9FAFB);

  // Compatibility names for existing screens.
  static const Color bgLight = backgroundApp;
  static const Color bgSurface = surfaceLight;
  static const Color bgMuted = surfaceMuted;
  static const Color bgInput = inputLight;

  // ==========================================================
  // DARK (Premium Slate Theme)
  // ==========================================================

  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceDarkMuted = Color(0xFF334155); // Slate 700

  static const Color inputDark = Color(0xFF1E293B);

  // ==========================================================
  // TEXT
  // ==========================================================

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color textDark = Color(0xFFF8FAFC);         // Slate 50
  static const Color textDarkSecondary = Color(0xFF94A3B8); // Slate 400

  // ==========================================================
  // BORDER
  // ==========================================================

  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF334155);       // Slate 700

  static const Color divider = Color(0xFFE5E7EB);

  // ==========================================================
  // STATUS
  // ==========================================================

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ==========================================================
  // GRADIENTS
  // ==========================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primary,
      accent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      primary,
      accent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // DYNAMIC HELPERS
  // ==========================================================

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBg(BuildContext context) {
    return isDarkMode(context) ? backgroundDark : backgroundApp;
  }

  static Color getSurface(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surfaceLight;
  }

  static Color getTextColor(BuildContext context) {
    return isDarkMode(context) ? textDark : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDarkMode(context) ? textDarkSecondary : textSecondary;
  }

  static Color getBorder(BuildContext context) {
    return isDarkMode(context) ? borderDark : borderLight;
  }

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [
      accent,
      accentPurple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [
      accentPurple,
      accentPink,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [
      Color(0xFFE0F2FE),
      Color(0xFFE0F4F3),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ==========================================================
  // RADIUS
  // ==========================================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;

  // ==========================================================
  // LIGHT THEME
  // ==========================================================

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: backgroundApp,

      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundApp,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(
            color: borderLight,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputLight,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: borderLight,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: borderLight,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: error,
            width: 1.5,
          ),
        ),

        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
        ),

        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    );
  }

  // ==========================================================
  // DARK THEME
  // ==========================================================

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: backgroundDark,

      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textDark,
        error: error,
        onError: Colors.white,
      ),

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(
            color: borderDark,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: borderDark,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: borderDark,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: primaryLight,
            width: 1.5,
          ),
        ),

        hintStyle: const TextStyle(
          color: textDarkSecondary,
          fontSize: 14,
        ),

        labelStyle: const TextStyle(
          color: textDarkSecondary,
          fontSize: 13,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(
            color: primaryLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
        ),
      ),

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryLight,
        unselectedItemColor: textDarkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    );
  }
}