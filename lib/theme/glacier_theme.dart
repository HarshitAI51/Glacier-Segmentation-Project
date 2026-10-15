import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlacierColors {
  // Canvas & Backgrounds
  static const Color canvas = Color(0xFFF4F3EF); // Warm bone / off-white
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFECEAE5);
  static const Color border = Color(0xFFE5E3DE);

  // Deep Accents (Sidebar, primary buttons)
  static const Color darkForest = Color(0xFF19231F); // Dark charcoal sage
  static const Color darkHover = Color(0xFF26332E);
  static const Color darkSecondary = Color(0xFF232D29);

  // Sage & Forest Greens
  static const Color sage = Color(0xFF4C6E5F);
  static const Color sageLight = Color(0xFFE8EFEA);
  static const Color sageText = Color(0xFF26493B);

  // Soft Pastels for Metric Cards (Inspired by Reference UI)
  static const Color pastelYellow = Color(0xFFFBF4DF);
  static const Color pastelYellowText = Color(0xFF6B5317);

  static const Color pastelPink = Color(0xFFFBECEF);
  static const Color pastelPinkText = Color(0xFF7A2A38);

  static const Color pastelBlue = Color(0xFFE7F1F8);
  static const Color pastelBlueText = Color(0xFF1B4965);

  static const Color pastelGreen = Color(0xFFE5ECE7);
  static const Color pastelGreenText = Color(0xFF2B523F);

  // Text Colors
  static const Color textPrimary = Color(0xFF181F1C);
  static const Color textSecondary = Color(0xFF69726D);
  static const Color textMuted = Color(0xFF98A09B);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
}

class GlacierTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: GlacierColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GlacierColors.sage,
        surface: GlacierColors.card,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: GlacierColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: GlacierColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: GlacierColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: GlacierColors.textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: GlacierColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: GlacierColors.border, width: 0.8),
        ),
      ),
    );
  }
}

// Box shadow helper for clean aesthetic
List<BoxShadow> get glacierSoftShadow => [
      const BoxShadow(
        color: Color(0x07000000),
        blurRadius: 18,
        offset: Offset(0, 4),
      ),
    ];
