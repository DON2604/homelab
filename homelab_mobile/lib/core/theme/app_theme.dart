import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _background = Color(0xFF0D0D0F);
  static const Color _surface = Color(0xFF1A1A1E);
  static const Color _surfaceVariant = Color(0xFF242428);
  static const Color _accent = Color(0xFF7C6FCD); // soft purple
  static const Color _accentLight = Color(0xFFB3A9E8);
  static const Color _onAccent = Colors.white;
  static const Color _onBackground = Color(0xFFEAEAF0);
  static const Color _onSurface = Color(0xFFCCCCD6);
  static const Color _outline = Color(0xFF3A3A42);

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: _accent,
      onPrimary: _onAccent,
      primaryContainer: Color(0xFF3D3470),
      onPrimaryContainer: _accentLight,
      secondary: Color(0xFF6FBFb8),
      onSecondary: Colors.black,
      surface: _surface,
      onSurface: _onSurface,
      surfaceContainerHighest: _surfaceVariant,
      outline: _outline,
      scrim: Colors.black87,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        color: _onBackground,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        color: _onBackground,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        color: _onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        color: _onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.inter(
        color: _onSurface,
        fontSize: 14,
      ),
      labelSmall: GoogleFonts.inter(
        color: _onSurface.withAlpha(180),
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: _onBackground),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _onBackground,
          highlightColor: _accent.withAlpha(40),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _onAccent,
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _outline,
        thickness: 0.5,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceVariant,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _onBackground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Convenience getters ──────────────────────────────────────────────────
  static Color get accent => _accent;
  static Color get background => _background;
  static Color get surface => _surface;
  static Color get surfaceVariant => _surfaceVariant;
  static Color get onBackground => _onBackground;
  static Color get onSurface => _onSurface;
  static Color get outline => _outline;
}
