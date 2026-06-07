// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────
// WARNA
// ──────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color primary      = Color(0xFF6BBFB5);
  static const Color primaryLight = Color(0xFFB2DED9);
  static const Color primaryDark  = Color(0xFF4A9E94);

  static const Color secondary      = Color(0xFFFFB347);
  static const Color secondaryLight = Color(0xFFFFD4A0);

  static const Color accent = Color(0xFFA8D8EA);

  static const Color bgMain    = Color(0xFFF5F9F8);
  static const Color bgCard    = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFEDF6F4);

  static const Color textPrimary   = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textHint      = Color(0xFFA0AEC0);

  static const Color success = Color(0xFF68D391);
  static const Color warning = Color(0xFFF6AD55);
  static const Color danger  = Color(0xFFFC8181);

  static const Color streakFire = Color(0xFFFF6B35);
  static const Color xpPurple   = Color(0xFFB8A9FF);
  static const Color shieldBlue = Color(0xFF74B3CE);

  static const Color sweetAmber   = Color(0xFFFFB347);
  static const Color sweetWarning = Color(0xFFFF8C42);
  static const Color sweetDanger  = Color(0xFFE05252);
}

// ──────────────────────────────────────────────────────────────
// THEME
// ──────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.bgMain,
    ),
    scaffoldBackgroundColor: AppColors.bgMain,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito'),
      hintStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
    ),

    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 11,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: 'Nunito', fontSize: 11),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontFamily: 'Nunito', color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontFamily: 'Nunito', color: AppColors.textSecondary),
      labelSmall: TextStyle(fontFamily: 'Nunito', color: AppColors.textHint),
    ),
  );
}