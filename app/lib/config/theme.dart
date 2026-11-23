/// Speakaboo Design Tokens
///
/// All colors, typography, and spacing in one file.
/// No hardcoded colors elsewhere.
library;

import 'package:flutter/material.dart';

class SpeakabooTheme {
  SpeakabooTheme._();

  // === 60-30-10 Color System ===
  static const Color background = Color(0xFFFBF8F5); // 60% warm off-white
  static const Color surface = Color(0xFFF1E9E1);     // 30% surfaces
  static const Color accent = Color(0xFFF26B21);       // 10% accent orange
  static const Color textPrimary = Color(0xFF2A211B);  // text color
  static const Color textSecondary = Color(0xFF6B5D52); // secondary text
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  // === Typography ===
  static const double baseFontSize = 17.0;
  static const double headingSize = 24.0;
  static const double subheadingSize = 18.0;
  static const double captionSize = 13.0;
  static const double smallSize = 11.0;

  // === Spacing ===
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // === Radius ===
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusFull = 999.0;

  // === Tap targets ===
  static const double minTapTarget = 44.0;

  static ThemeData get theme => ThemeData(
    colorScheme: const ColorScheme.light(
      surface: background,
      surfaceContainerHighest: surface,
      primary: accent,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      error: error,
    ),
    scaffoldBackgroundColor: background,
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: headingSize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: baseFontSize,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: captionSize,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: smallSize,
        color: textSecondary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(minTapTarget, minTapTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: accent.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: captionSize,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          );
        }
        return const TextStyle(
          fontSize: captionSize,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accent, size: 26);
        }
        return const IconThemeData(color: textSecondary, size: 24);
      }),
    ),
  );
}
