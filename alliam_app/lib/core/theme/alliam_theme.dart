import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'alliam_colors.dart';

abstract final class AlliamTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AlliamColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AlliamColors.coral,
        secondary: AlliamColors.coralSoft,
        surface: AlliamColors.surface,
        onPrimary: Colors.white,
        onSurface: AlliamColors.text,
        error: AlliamColors.error,
      ),
    );

    return base.copyWith(
      iconTheme: const IconThemeData(color: AlliamColors.text),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: AlliamColors.text, displayColor: AlliamColors.text),
      dividerTheme: const DividerThemeData(
        color: Color(0x55EEE3DB),
        thickness: 0.7,
        space: 1,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AlliamColors.coral,
          side: const BorderSide(color: AlliamColors.line),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AlliamColors.coral),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AlliamColors.surfaceStrong,
        selectedColor: AlliamColors.coralSoft,
        side: const BorderSide(color: AlliamColors.line),
        labelStyle: const TextStyle(color: AlliamColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AlliamColors.surfaceStrong,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: AlliamColors.text),
        hintStyle: const TextStyle(color: AlliamColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AlliamColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AlliamColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AlliamColors.coral, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AlliamColors.coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: AlliamColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AlliamColors.line),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AlliamColors.surfaceStrong,
        textStyle: GoogleFonts.plusJakartaSans(color: AlliamColors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AlliamColors.line),
        ),
      ),
    );
  }
}
