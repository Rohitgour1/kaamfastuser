import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette sampled from `assets/images/logo.png` (KaamFast K mark).
class AppColors {
  static const navy = Color(0xFF01193D);
  static const navyDeep = Color(0xFF001838);
  static const navySoft = Color(0xFF0E2C52);
  static const sky = Color(0xFFFFF1E6);
  static const skySoft = Color(0xFFFFF8F2);
  static const lavender = Color(0xFFFFE8D6);
  static const lavenderText = Color(0xFFC44A00);
  static const gold = Color(0xFFFF8A00);
  static const goldSoft = Color(0xFFFFB347);
  static const mist = Color(0xFFF8F9FB);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const success = Color(0xFF059669);
  static const danger = Color(0xFFD32F2F);
  static const accentOrange = Color(0xFFFF5E01);

  // Legacy aliases used across older screens
  static const teal = navy;
  static const tealSoft = navySoft;
  static const sand = goldSoft;
  static const coral = accentOrange;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.accentOrange,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.navy, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.navy : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.navy : AppColors.muted);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
