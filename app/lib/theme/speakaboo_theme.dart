/// Speakaboo Playful Design System
///
/// Warm cream & deep midnight purple theme tokens with Fredoka + Nunito + Hind Siliguri
/// typography, pastel topic washes, chunky 3D button edges, and ThemeExtension.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme-aware design tokens accessible via `context.colors` or `SpeakabooTheme.of(context)`.
class SpeakabooColors extends ThemeExtension<SpeakabooColors> {
  // Core surfaces & text
  final Color background;
  final Color surface;
  final Color surfaceWarm;
  final Color textPrimary;
  final Color textSecondary;

  // Primary action (Violet in light, Luminous Lavender in dark)
  final Color primary;
  final Color onPrimary;
  final Color primaryEdge;

  // Semantic accents (always paired with accentText #2B2140 on bright fills)
  final Color accent; // Alias to primary for backward compatibility
  final Color coral; // Streak & microphone
  final Color coralEdge;
  final Color sunny; // XP, rewards, marker highlight
  final Color sunnyEdge;
  final Color mint; // Success
  final Color mintEdge;
  final Color sky; // Information
  final Color skyEdge;
  final Color accentText;

  // Status aliases (kept for backward compatibility)
  final Color success;
  final Color error;
  final Color warning;

  // Pastel washes for topic, mode, and character cards
  final Color pastelPink;
  final Color pastelYellow;
  final Color pastelMint;
  final Color pastelSky;
  final Color pastelLavender;

  // Elevation & borders
  final Color cardShadow;
  final Color borderSubtle;

  const SpeakabooColors({
    required this.background,
    required this.surface,
    required this.surfaceWarm,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.primaryEdge,
    required this.accent,
    required this.coral,
    required this.coralEdge,
    required this.sunny,
    required this.sunnyEdge,
    required this.mint,
    required this.mintEdge,
    required this.sky,
    required this.skyEdge,
    required this.accentText,
    required this.success,
    required this.error,
    required this.warning,
    required this.pastelPink,
    required this.pastelYellow,
    required this.pastelMint,
    required this.pastelSky,
    required this.pastelLavender,
    required this.cardShadow,
    required this.borderSubtle,
  });

  static const light = SpeakabooColors(
    background: SpeakabooTheme.background,
    surface: SpeakabooTheme.surface,
    surfaceWarm: SpeakabooTheme.surfaceWarm,
    textPrimary: SpeakabooTheme.textPrimary,
    textSecondary: SpeakabooTheme.textSecondary,
    primary: SpeakabooTheme.primary,
    onPrimary: Colors.white,
    primaryEdge: SpeakabooTheme.primaryEdge,
    accent: SpeakabooTheme.primary,
    coral: SpeakabooTheme.coral,
    coralEdge: SpeakabooTheme.coralEdge,
    sunny: SpeakabooTheme.sunny,
    sunnyEdge: SpeakabooTheme.sunnyEdge,
    mint: SpeakabooTheme.mint,
    mintEdge: SpeakabooTheme.mintEdge,
    sky: SpeakabooTheme.sky,
    skyEdge: SpeakabooTheme.skyEdge,
    accentText: SpeakabooTheme.textPrimary,
    success: SpeakabooTheme.mint,
    error: SpeakabooTheme.coral,
    warning: SpeakabooTheme.sunny,
    pastelPink: SpeakabooTheme.pastelPinkLight,
    pastelYellow: SpeakabooTheme.pastelYellowLight,
    pastelMint: SpeakabooTheme.pastelMintLight,
    pastelSky: SpeakabooTheme.pastelSkyLight,
    pastelLavender: SpeakabooTheme.pastelLavenderLight,
    cardShadow: Color(0x142B2140),
    borderSubtle: Color(0x142B2140),
  );

  static const dark = SpeakabooColors(
    background: SpeakabooTheme.darkBackground,
    surface: SpeakabooTheme.darkSurface,
    surfaceWarm: SpeakabooTheme.darkSurfaceElevated,
    textPrimary: SpeakabooTheme.darkTextPrimary,
    textSecondary: SpeakabooTheme.darkTextSecondary,
    primary: SpeakabooTheme.darkPrimary,
    onPrimary: SpeakabooTheme.darkBackground,
    primaryEdge: SpeakabooTheme.darkPrimaryEdge,
    accent: SpeakabooTheme.darkPrimary,
    coral: SpeakabooTheme.coral,
    coralEdge: SpeakabooTheme.coralEdge,
    sunny: SpeakabooTheme.sunny,
    sunnyEdge: SpeakabooTheme.sunnyEdge,
    mint: SpeakabooTheme.mint,
    mintEdge: SpeakabooTheme.mintEdge,
    sky: SpeakabooTheme.sky,
    skyEdge: SpeakabooTheme.skyEdge,
    accentText: SpeakabooTheme.textPrimary,
    success: SpeakabooTheme.mint,
    error: SpeakabooTheme.coral,
    warning: SpeakabooTheme.sunny,
    pastelPink: SpeakabooTheme.pastelPinkDark,
    pastelYellow: SpeakabooTheme.pastelYellowDark,
    pastelMint: SpeakabooTheme.pastelMintDark,
    pastelSky: SpeakabooTheme.pastelSkyDark,
    pastelLavender: SpeakabooTheme.pastelLavenderDark,
    cardShadow: Color(0x00000000),
    borderSubtle: Color(0x1FF6F2FF),
  );

  @override
  SpeakabooColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceWarm,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? onPrimary,
    Color? primaryEdge,
    Color? accent,
    Color? coral,
    Color? coralEdge,
    Color? sunny,
    Color? sunnyEdge,
    Color? mint,
    Color? mintEdge,
    Color? sky,
    Color? skyEdge,
    Color? accentText,
    Color? success,
    Color? error,
    Color? warning,
    Color? pastelPink,
    Color? pastelYellow,
    Color? pastelMint,
    Color? pastelSky,
    Color? pastelLavender,
    Color? cardShadow,
    Color? borderSubtle,
  }) {
    return SpeakabooColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceWarm: surfaceWarm ?? this.surfaceWarm,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryEdge: primaryEdge ?? this.primaryEdge,
      accent: accent ?? this.accent,
      coral: coral ?? this.coral,
      coralEdge: coralEdge ?? this.coralEdge,
      sunny: sunny ?? this.sunny,
      sunnyEdge: sunnyEdge ?? this.sunnyEdge,
      mint: mint ?? this.mint,
      mintEdge: mintEdge ?? this.mintEdge,
      sky: sky ?? this.sky,
      skyEdge: skyEdge ?? this.skyEdge,
      accentText: accentText ?? this.accentText,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      pastelPink: pastelPink ?? this.pastelPink,
      pastelYellow: pastelYellow ?? this.pastelYellow,
      pastelMint: pastelMint ?? this.pastelMint,
      pastelSky: pastelSky ?? this.pastelSky,
      pastelLavender: pastelLavender ?? this.pastelLavender,
      cardShadow: cardShadow ?? this.cardShadow,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  SpeakabooColors lerp(ThemeExtension<SpeakabooColors>? other, double t) {
    if (other is! SpeakabooColors) return this;
    return SpeakabooColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceWarm: Color.lerp(surfaceWarm, other.surfaceWarm, t) ?? surfaceWarm,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      primaryEdge: Color.lerp(primaryEdge, other.primaryEdge, t) ?? primaryEdge,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      coral: Color.lerp(coral, other.coral, t) ?? coral,
      coralEdge: Color.lerp(coralEdge, other.coralEdge, t) ?? coralEdge,
      sunny: Color.lerp(sunny, other.sunny, t) ?? sunny,
      sunnyEdge: Color.lerp(sunnyEdge, other.sunnyEdge, t) ?? sunnyEdge,
      mint: Color.lerp(mint, other.mint, t) ?? mint,
      mintEdge: Color.lerp(mintEdge, other.mintEdge, t) ?? mintEdge,
      sky: Color.lerp(sky, other.sky, t) ?? sky,
      skyEdge: Color.lerp(skyEdge, other.skyEdge, t) ?? skyEdge,
      accentText: Color.lerp(accentText, other.accentText, t) ?? accentText,
      success: Color.lerp(success, other.success, t) ?? success,
      error: Color.lerp(error, other.error, t) ?? error,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      pastelPink: Color.lerp(pastelPink, other.pastelPink, t) ?? pastelPink,
      pastelYellow: Color.lerp(pastelYellow, other.pastelYellow, t) ?? pastelYellow,
      pastelMint: Color.lerp(pastelMint, other.pastelMint, t) ?? pastelMint,
      pastelSky: Color.lerp(pastelSky, other.pastelSky, t) ?? pastelSky,
      pastelLavender: Color.lerp(pastelLavender, other.pastelLavender, t) ?? pastelLavender,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t) ?? cardShadow,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
    );
  }
}

class SpeakabooTheme {
  SpeakabooTheme._();

  // === Light Palette ===
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFFF3E7);
  static const Color textPrimary = Color(0xFF2B2140);
  static const Color textSecondary = Color(0xFF6B6280);
  static const Color primary = Color(0xFF6C4DF6);
  static const Color primaryEdge = Color(0xFF5133D6);

  // === Dark Palette ===
  static const Color darkBackground = Color(0xFF17132A);
  static const Color darkSurface = Color(0xFF241E3D);
  static const Color darkSurfaceElevated = Color(0xFF2F284E);
  static const Color darkTextPrimary = Color(0xFFF6F2FF);
  static const Color darkTextSecondary = Color(0xFFB8B0D4);
  static const Color darkPrimary = Color(0xFFA18CFF);
  static const Color darkPrimaryEdge = Color(0xFF7960E5);

  // === Shared Playful Accents (paired with #2B2140 text) ===
  static const Color coral = Color(0xFFFF7A6B);
  static const Color coralEdge = Color(0xFFD95648);
  static const Color sunny = Color(0xFFFFC83D);
  static const Color sunnyEdge = Color(0xFFD89F12);
  static const Color mint = Color(0xFF34D3A2);
  static const Color mintEdge = Color(0xFF1DA87D);
  static const Color sky = Color(0xFF55C4FF);
  static const Color skyEdge = Color(0xFF2B9AD6);

  // === Pastel Card Washes (adapted from reference) ===
  static const Color pastelPinkLight = Color(0xFFFEE3EC);
  static const Color pastelYellowLight = Color(0xFFFEF3D5);
  static const Color pastelMintLight = Color(0xFFE2F7E8);
  static const Color pastelSkyLight = Color(0xFFEAF2FF);
  static const Color pastelLavenderLight = Color(0xFFF0EAFF);

  static const Color pastelPinkDark = Color(0xFF3B2438);
  static const Color pastelYellowDark = Color(0xFF383020);
  static const Color pastelMintDark = Color(0xFF1D3832);
  static const Color pastelSkyDark = Color(0xFF1F3047);
  static const Color pastelLavenderDark = Color(0xFF2C244A);

  // Backward-compatible aliases
  static const Color accent = primary;
  static const Color darkAccent = darkPrimary;
  static const Color success = mint;
  static const Color error = coral;
  static const Color warning = sunny;

  // === Typography Scale (32 / 24 / 18 / 16 / 13) ===
  static const double displaySize = 32.0;
  static const double headingSize = 24.0;
  static const double subheadingSize = 18.0;
  static const double baseFontSize = 16.0;
  static const double captionSize = 13.0;
  static const double smallSize = 13.0;

  // === Spacing (4, 8, 12, 16, 24, 32) ===
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacing12 = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // === Shape & Depth ===
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusCard = 24.0;
  static const double radiusFull = 999.0;
  static const double buttonHeight = 56.0;
  static const double buttonEdgeDepth = 4.0;
  static const double minTapTarget = 48.0;

  /// Quick helper to get theme-aware colors from current context.
  static SpeakabooColors of(BuildContext context) {
    return Theme.of(context).extension<SpeakabooColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? SpeakabooColors.dark
            : SpeakabooColors.light);
  }

  /// Display heading style using Fredoka + Hind Siliguri fallback for Bangla.
  static TextStyle displayStyle({
    required Color color,
    double size = displaySize,
    FontWeight weight = FontWeight.w700,
    double height = 1.15,
  }) {
    final base = GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
    final banglaFamily = GoogleFonts.hindSiliguri().fontFamily;
    return base.copyWith(
      fontFamilyFallback: [if (banglaFamily != null) banglaFamily],
    );
  }

  /// Body text style using Nunito + Hind Siliguri fallback for Bangla.
  static TextStyle bodyStyle({
    required Color color,
    double size = baseFontSize,
    FontWeight weight = FontWeight.w600,
    double height = 1.4,
  }) {
    final base = GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
    final banglaFamily = GoogleFonts.hindSiliguri().fontFamily;
    return base.copyWith(
      fontFamilyFallback: [if (banglaFamily != null) banglaFamily],
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    final banglaFamily = GoogleFonts.hindSiliguri().fontFamily;
    final fallback = [if (banglaFamily != null) banglaFamily];
    final bodyTheme = GoogleFonts.nunitoTextTheme();

    return bodyTheme.copyWith(
      displaySmall: GoogleFonts.fredoka(
        fontSize: displaySize,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.15,
      ).copyWith(fontFamilyFallback: fallback),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: headingSize,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.2,
      ).copyWith(fontFamilyFallback: fallback),
      titleMedium: GoogleFonts.fredoka(
        fontSize: subheadingSize,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.25,
      ).copyWith(fontFamilyFallback: fallback),
      bodyLarge: GoogleFonts.nunito(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ).copyWith(fontFamilyFallback: fallback),
      bodyMedium: GoogleFonts.nunito(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ).copyWith(fontFamilyFallback: fallback),
      bodySmall: GoogleFonts.nunito(
        fontSize: captionSize,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ).copyWith(fontFamilyFallback: fallback),
      labelLarge: GoogleFonts.fredoka(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ).copyWith(fontFamilyFallback: fallback),
      labelSmall: GoogleFonts.nunito(
        fontSize: captionSize,
        fontWeight: FontWeight.w700,
        color: secondaryColor,
      ).copyWith(fontFamilyFallback: fallback),
    );
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      surface: surface,
      surfaceContainerHighest: surfaceWarm,
      primary: primary,
      onPrimary: Colors.white,
      secondary: sunny,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      error: coral,
      onError: textPrimary,
    ),
    scaffoldBackgroundColor: background,
    extensions: const [SpeakabooColors.light],
    textTheme: _buildTextTheme(textPrimary, textSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: displayStyle(color: textPrimary, size: headingSize),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(minTapTarget, buttonHeight),
        shape: const StadiumBorder(),
        textStyle: displayStyle(color: Colors.white, size: baseFontSize),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      titleTextStyle: displayStyle(color: textPrimary, size: headingSize),
      contentTextStyle: bodyStyle(color: textPrimary, size: baseFontSize),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      indicatorColor: primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return bodyStyle(
          color: selected ? primary : textSecondary,
          size: captionSize,
          weight: selected ? FontWeight.w800 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primary : textSecondary,
          size: selected ? 26 : 24,
        );
      }),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: darkSurface,
      surfaceContainerHighest: darkSurfaceElevated,
      primary: darkPrimary,
      onPrimary: darkBackground,
      secondary: sunny,
      onSecondary: textPrimary,
      onSurface: darkTextPrimary,
      error: coral,
      onError: textPrimary,
    ),
    scaffoldBackgroundColor: darkBackground,
    extensions: const [SpeakabooColors.dark],
    textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: displayStyle(color: darkTextPrimary, size: headingSize),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: darkBackground,
        minimumSize: const Size(minTapTarget, buttonHeight),
        shape: const StadiumBorder(),
        textStyle: displayStyle(color: darkBackground, size: baseFontSize),
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      titleTextStyle: displayStyle(color: darkTextPrimary, size: headingSize),
      contentTextStyle: bodyStyle(color: darkTextPrimary, size: baseFontSize),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      modalBackgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      elevation: 0,
      indicatorColor: darkPrimary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return bodyStyle(
          color: selected ? darkPrimary : darkTextSecondary,
          size: captionSize,
          weight: selected ? FontWeight.w800 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? darkPrimary : darkTextSecondary,
          size: selected ? 26 : 24,
        );
      }),
    ),
  );
}

/// Convenience context extensions.
extension BuildContextThemeExtension on BuildContext {
  SpeakabooColors get colors => SpeakabooTheme.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
