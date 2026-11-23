/// Speakaboo Design Tokens
///
/// 60-30-10 warm color system in Light and Dark themes.
/// Includes WCAG AA compliant contrast (>= 4.5:1), min 44px tap targets,
/// and ThemeExtension for theme-aware component styling.
library;

import 'package:flutter/material.dart';

/// Theme-aware design tokens accessible via Theme.of(context).extension<SpeakabooColors>()
/// or SpeakabooTheme.of(context).
class SpeakabooColors extends ThemeExtension<SpeakabooColors> {
  final Color background;
  final Color surface;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color error;
  final Color warning;

  const SpeakabooColors({
    required this.background,
    required this.surface,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.error,
    required this.warning,
  });

  static const light = SpeakabooColors(
    background: SpeakabooTheme.background,
    surface: SpeakabooTheme.surface,
    accent: SpeakabooTheme.accent,
    textPrimary: SpeakabooTheme.textPrimary,
    textSecondary: SpeakabooTheme.textSecondary,
    success: SpeakabooTheme.success,
    error: SpeakabooTheme.error,
    warning: SpeakabooTheme.warning,
  );

  static const dark = SpeakabooColors(
    background: SpeakabooTheme.darkBackground,
    surface: SpeakabooTheme.darkSurface,
    accent: SpeakabooTheme.darkAccent,
    textPrimary: SpeakabooTheme.darkTextPrimary,
    textSecondary: SpeakabooTheme.darkTextSecondary,
    success: Color(0xFF66BB6A),
    error: Color(0xFFEF5350),
    warning: Color(0xFFFFB74D),
  );

  @override
  SpeakabooColors copyWith({
    Color? background,
    Color? surface,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? error,
    Color? warning,
  }) {
    return SpeakabooColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
    );
  }

  @override
  SpeakabooColors lerp(ThemeExtension<SpeakabooColors>? other, double t) {
    if (other is! SpeakabooColors) return this;
    return SpeakabooColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      success: Color.lerp(success, other.success, t) ?? success,
      error: Color.lerp(error, other.error, t) ?? error,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
    );
  }
}

class SpeakabooTheme {
  SpeakabooTheme._();

  // === 60-30-10 Light Palette ===
  static const Color background = Color(0xFFFBF8F5);    // 60% warm off-white
  static const Color surface = Color(0xFFF1E9E1);        // 30% warm sand surface
  static const Color accent = Color(0xFFF26B21);         // 10% vivid terracotta accent
  static const Color textPrimary = Color(0xFF2A211B);     // high-contrast brown-black (13:1)
  static const Color textSecondary = Color(0xFF6B5D52);   // medium brown-grey (5.2:1)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  // === 60-30-10 Warm Dark Palette (Phase 8) ===
  static const Color darkBackground = Color(0xFF1B1613); // 60% deep warm espresso
  static const Color darkSurface = Color(0xFF2A221D);    // 30% warm charcoal-brown surface
  static const Color darkAccent = Color(0xFFFF7A33);     // 10% luminous warm orange (5.5:1 on dark)
  static const Color darkTextPrimary = Color(0xFFF5EDE6);// warm parchment white (15.2:1 contrast)
  static const Color darkTextSecondary = Color(0xFFC4B8B0);// soft neutral stone (8.4:1 contrast)

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

  // === Tap targets (Accessibility: minimum 44px) ===
  static const double minTapTarget = 44.0;

  /// Quick helper to get theme-aware colors from current context.
  static SpeakabooColors of(BuildContext context) {
    return Theme.of(context).extension<SpeakabooColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? SpeakabooColors.dark
            : SpeakabooColors.light);
  }

  // --- Light Theme ---
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
    extensions: const [SpeakabooColors.light],
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
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

  // --- Dark Theme (Phase 8) ---
  static ThemeData get darkTheme => ThemeData(
    colorScheme: const ColorScheme.dark(
      surface: darkBackground,
      surfaceContainerHighest: darkSurface,
      primary: darkAccent,
      onPrimary: Colors.white,
      onSurface: darkTextPrimary,
      error: Color(0xFFEF5350),
    ),
    scaffoldBackgroundColor: darkBackground,
    useMaterial3: true,
    extensions: const [SpeakabooColors.dark],
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkTextPrimary,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: headingSize,
        fontWeight: FontWeight.bold,
        color: darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: baseFontSize,
        color: darkTextPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: captionSize,
        color: darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: smallSize,
        color: darkTextSecondary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(minTapTarget, minTapTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: darkSurface,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: headingSize - 4,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: baseFontSize - 2,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      modalBackgroundColor: darkSurface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: darkAccent.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: captionSize,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          );
        }
        return const TextStyle(
          fontSize: captionSize,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: darkAccent, size: 26);
        }
        return const IconThemeData(color: darkTextSecondary, size: 24);
      }),
    ),
  );
}

/// Convenience context extensions.
extension BuildContextThemeExtension on BuildContext {
  SpeakabooColors get colors => SpeakabooTheme.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
