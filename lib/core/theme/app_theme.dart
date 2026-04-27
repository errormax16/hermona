import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors – palette complète de l'application
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary      = Color(0xFFE8A4A4);
  static const Color primaryDark  = Color(0xFFC97B7B);
  static const Color primaryLight = Color(0xFFF5D0D0);
  static const Color secondary    = Color(0xFFD4A0C0);
  static const Color accent       = Color(0xFFB8D4C8);

  static const Color bgLight      = Color(0xFFFDF8F8);
  static const Color bgDark       = Color(0xFF1A1217);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark  = Color(0xFF2A1F24);
  static const Color cardLight    = Color(0xFFFFF0F0);
  static const Color cardDark     = Color(0xFF332530);

  static const Color textPrimaryLight   = Color(0xFF2C1810);
  static const Color textSecondaryLight = Color(0xFF7A5C60);
  static const Color textPrimaryDark    = Color(0xFFF5E8E8);
  static const Color textSecondaryDark  = Color(0xFFB89090);

  static const Color success = Color(0xFF7BBFA0);
  static const Color warning = Color(0xFFE8C87A);
  static const Color error   = Color(0xFFD97A7A);
  static const Color info    = Color(0xFF7AA8D9);

  static const Color dividerLight = Color(0xFFEDD5D5);
  static const Color dividerDark  = Color(0xFF4A2E35);

  static const Color severityNormal   = Color(0xFF7BBFA0);
  static const Color severityModerate = Color(0xFFE8C87A);
  static const Color severitySevere   = Color(0xFFD97A7A);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme – thème Material 3 avec couleur primaire dynamique
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static Color _primary = AppColors.primary;

  static void setPrimary(Color c) => _primary = c;
  static Color get primary => _primary;

  static ThemeData light() => _build(false);
  static ThemeData dark()  => _build(true);

  static ThemeData _build(bool isDark) {
    final bg      = isDark ? AppColors.bgDark      : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
    final card    = isDark ? AppColors.cardDark     : AppColors.cardLight;
    final textPri = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final textSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final divider = isDark ? AppColors.dividerDark  : AppColors.dividerLight;

    return (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness  : isDark ? Brightness.dark : Brightness.light,
        primary     : _primary,
        onPrimary   : Colors.white,
        secondary   : AppColors.secondary,
        onSecondary : Colors.white,
        surface     : surface,
        onSurface   : textPri,
        error       : AppColors.error,
        onError     : Colors.white,
        background  : bg,
        onBackground: textPri,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge  : GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold,  color: textPri),
        displayMedium : GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold,  color: textPri),
        displaySmall  : GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: textPri),
        headlineLarge : GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold,  color: textPri),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: textPri),
        bodyLarge  : GoogleFonts.dmSans(fontSize: 16, color: textPri),
        bodyMedium : GoogleFonts.dmSans(fontSize: 14, color: textPri),
        bodySmall  : GoogleFonts.dmSans(fontSize: 12, color: textSec),
        labelLarge : GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPri),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg, elevation: 0, centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: textPri),
        iconTheme: IconThemeData(color: textPri),
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: BorderSide(color: _primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border        : OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder : OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: divider, width: 1)),
        focusedBorder : OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary, width: 2)),
        errorBorder   : OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error)),
        hintStyle: GoogleFonts.dmSans(color: textSec, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: card, selectedColor: _primary.withOpacity(0.2),
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: BorderSide(color: divider),
      ),
    );
  }
}
