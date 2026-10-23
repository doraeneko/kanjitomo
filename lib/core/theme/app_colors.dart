import 'package:flutter/material.dart';

/// Semantic color tokens that adapt to light / dark brightness.
///
/// Material 3's [ColorScheme] already handles primary/surface/error surfaces,
/// but the app has many hand-picked grays and feedback tints that need explicit
/// light/dark variants. Register this extension on both the light and dark
/// [ThemeData] via [AppColors.light] / [AppColors.dark], then read it anywhere
/// with `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Secondary text (e.g. composita word headers, translation text).
  final Color textSecondary;

  /// Tertiary text (e.g. JLPT level badges, help text, source labels).
  final Color textTertiary;

  /// Disabled / de-emphasized text (e.g. rare readings, not-due kanji).
  final Color textDisabled;

  /// Standard border (e.g. drawing canvas, stroke order box).
  final Color border;

  /// Subtle border (e.g. progress dots, lighter separators).
  final Color borderSubtle;

  /// Review feedback: correct answer background / foreground.
  final Color successBg;
  final Color successFg;

  /// Review feedback: wrong answer background / foreground.
  final Color errorBg;
  final Color errorFg;

  /// Review feedback / statistics: in-progress / warning.
  final Color warningBg;
  final Color warningFg;

  /// Informational highlights (e.g. user sentence source label).
  final Color infoBg;
  final Color infoFg;

  /// Help/support card surface.
  final Color surfaceHelp;

  /// Drawing canvas — NEVER changes (ML model dependency).
  final Color canvasBg;
  final Color canvasInk;

  /// Semantic status colors for pie charts / progress dots.
  final Color statusGreen;
  final Color statusOrange;
  final Color statusRed;
  final Color statusBlue;
  final Color statusIndigo;
  final Color statusGrey;
  final Color statusGreyLight;

  /// Progress indicator background.
  final Color progressBg;

  /// Navigation bar selected-icon colors.
  final Color navLookup;
  final Color navWords;
  final Color navLearn;
  final Color navBrowse;
  final Color navHelp;

  /// Coffee button / support accent.
  final Color coffeeIcon;
  final Color coffeeBg;
  final Color coffeeFg;

  /// Link color for acknowledgement URLs.
  final Color linkColor;

  /// Tour scrim overlay.
  final Color tourScrim;

  /// Inactive tour step dot / similar.
  final Color dotInactive;

  const AppColors({
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
    required this.successBg,
    required this.successFg,
    required this.errorBg,
    required this.errorFg,
    required this.warningBg,
    required this.warningFg,
    required this.infoBg,
    required this.infoFg,
    required this.surfaceHelp,
    required this.canvasBg,
    required this.canvasInk,
    required this.statusGreen,
    required this.statusOrange,
    required this.statusRed,
    required this.statusBlue,
    required this.statusIndigo,
    required this.statusGrey,
    required this.statusGreyLight,
    required this.progressBg,
    required this.navLookup,
    required this.navWords,
    required this.navLearn,
    required this.navBrowse,
    required this.navHelp,
    required this.coffeeIcon,
    required this.coffeeBg,
    required this.coffeeFg,
    required this.linkColor,
    required this.tourScrim,
    required this.dotInactive,
  });

  static const light = AppColors(
    textSecondary: Color(0xFF616161), // grey.shade700
    textTertiary: Color(0xFF757575), // grey.shade600
    textDisabled: Color(0xFF9E9E9E), // grey.shade500
    border: Color(0xFFBDBDBD), // grey.shade400
    borderSubtle: Color(0xFFE0E0E0), // grey.shade300
    successBg: Color(0xFFC8E6C9), // green.shade100
    successFg: Color(0xFF388E3C), // green.shade700
    errorBg: Color(0xFFFFCDD2), // red.shade100
    errorFg: Color(0xFFD32F2F), // red.shade700
    warningBg: Color(0xFFFFE0B2), // orange.shade100
    warningFg: Color(0xFFEF6C00), // orange.shade800
    infoBg: Color(0xFFBBDEFB), // blue.shade100
    infoFg: Color(0xFF1976D2), // blue.shade700
    surfaceHelp: Color(0xFFFFF8E1), // amber.shade50
    // DO NOT THEME — ML model dependency
    canvasBg: Color(0xFFFFFFFF),
    canvasInk: Color(0xDD000000), // black87
    statusGreen: Color(0xFF4CAF50), // Colors.green
    statusOrange: Color(0xFFFF9800), // Colors.orange
    statusRed: Color(0xFFF44336), // Colors.red
    statusBlue: Color(0xFF2196F3), // Colors.blue
    statusIndigo: Color(0xFF3F51B5), // Colors.indigo
    statusGrey: Color(0xFF9E9E9E), // Colors.grey
    statusGreyLight: Color(0xFFE0E0E0), // grey.shade300
    progressBg: Color(0xFFEEEEEE), // grey.shade200
    navLookup: Color(0xFFBF360C), // deepOrange.shade700
    navWords: Color(0xFF00695C), // teal.shade700
    navLearn: Color(0xFFE65100), // orange.shade700 (approximated)
    navBrowse: Color(0xFF303F9F), // indigo.shade700
    navHelp: Color(0xFF616161), // grey.shade700
    coffeeIcon: Color(0xFFA1887F), // brown.shade300
    coffeeBg: Color(0xFFF9A825), // amber.shade700
    coffeeFg: Color(0xFFFFFFFF),
    linkColor: Color(0xFF1565C0), // blue.shade700
    tourScrim: Color(0x8A000000), // black54
    dotInactive: Color(0xFFE0E0E0), // grey.shade300
  );

  static const dark = AppColors(
    textSecondary: Color(0xFFBDBDBD), // grey.shade400
    textTertiary: Color(0xFF9E9E9E), // grey.shade500
    textDisabled: Color(0xFF757575), // grey.shade600
    border: Color(0xFF616161), // grey.shade700
    borderSubtle: Color(0xFF424242), // grey.shade800
    successBg: Color(0xFF1B5E20), // green.shade900
    successFg: Color(0xFF81C784), // green.shade300
    errorBg: Color(0xFFB71C1C), // red.shade900
    errorFg: Color(0xFFE57373), // red.shade300
    warningBg: Color(0xFFE65100), // orange.shade900
    warningFg: Color(0xFFFFB74D), // orange.shade300
    infoBg: Color(0xFF0D47A1), // blue.shade900
    infoFg: Color(0xFF64B5F6), // blue.shade300
    surfaceHelp: Color(0xFF2C2416), // amber-tinted dark surface
    // DO NOT THEME — ML model dependency
    canvasBg: Color(0xFFFFFFFF),
    canvasInk: Color(0xDD000000), // black87
    statusGreen: Color(0xFF66BB6A), // green.shade400
    statusOrange: Color(0xFFFFA726), // orange.shade400
    statusRed: Color(0xFFEF5350), // red.shade400
    statusBlue: Color(0xFF42A5F5), // blue.shade400
    statusIndigo: Color(0xFF7986CB), // indigo.shade300
    statusGrey: Color(0xFF9E9E9E), // Colors.grey
    statusGreyLight: Color(0xFF616161), // grey.shade700
    progressBg: Color(0xFF424242), // grey.shade800
    navLookup: Color(0xFFFF8A65), // deepOrange.shade300
    navWords: Color(0xFF80CBC4), // teal.shade200
    navLearn: Color(0xFFFFB74D), // orange.shade300
    navBrowse: Color(0xFF9FA8DA), // indigo.shade200
    navHelp: Color(0xFFBDBDBD), // grey.shade400
    coffeeIcon: Color(0xFFBCAAA4), // brown.shade200
    coffeeBg: Color(0xFFF9A825), // amber.shade700
    coffeeFg: Color(0xFFFFFFFF),
    linkColor: Color(0xFF64B5F6), // blue.shade300
    tourScrim: Color(0xCC000000), // slightly darker for dark mode
    dotInactive: Color(0xFF616161), // grey.shade700
  );

  @override
  AppColors copyWith({
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? successBg,
    Color? successFg,
    Color? errorBg,
    Color? errorFg,
    Color? warningBg,
    Color? warningFg,
    Color? infoBg,
    Color? infoFg,
    Color? surfaceHelp,
    Color? canvasBg,
    Color? canvasInk,
    Color? statusGreen,
    Color? statusOrange,
    Color? statusRed,
    Color? statusBlue,
    Color? statusIndigo,
    Color? statusGrey,
    Color? statusGreyLight,
    Color? progressBg,
    Color? navLookup,
    Color? navWords,
    Color? navLearn,
    Color? navBrowse,
    Color? navHelp,
    Color? coffeeIcon,
    Color? coffeeBg,
    Color? coffeeFg,
    Color? linkColor,
    Color? tourScrim,
    Color? dotInactive,
  }) {
    return AppColors(
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      errorBg: errorBg ?? this.errorBg,
      errorFg: errorFg ?? this.errorFg,
      warningBg: warningBg ?? this.warningBg,
      warningFg: warningFg ?? this.warningFg,
      infoBg: infoBg ?? this.infoBg,
      infoFg: infoFg ?? this.infoFg,
      surfaceHelp: surfaceHelp ?? this.surfaceHelp,
      canvasBg: canvasBg ?? this.canvasBg,
      canvasInk: canvasInk ?? this.canvasInk,
      statusGreen: statusGreen ?? this.statusGreen,
      statusOrange: statusOrange ?? this.statusOrange,
      statusRed: statusRed ?? this.statusRed,
      statusBlue: statusBlue ?? this.statusBlue,
      statusIndigo: statusIndigo ?? this.statusIndigo,
      statusGrey: statusGrey ?? this.statusGrey,
      statusGreyLight: statusGreyLight ?? this.statusGreyLight,
      progressBg: progressBg ?? this.progressBg,
      navLookup: navLookup ?? this.navLookup,
      navWords: navWords ?? this.navWords,
      navLearn: navLearn ?? this.navLearn,
      navBrowse: navBrowse ?? this.navBrowse,
      navHelp: navHelp ?? this.navHelp,
      coffeeIcon: coffeeIcon ?? this.coffeeIcon,
      coffeeBg: coffeeBg ?? this.coffeeBg,
      coffeeFg: coffeeFg ?? this.coffeeFg,
      linkColor: linkColor ?? this.linkColor,
      tourScrim: tourScrim ?? this.tourScrim,
      dotInactive: dotInactive ?? this.dotInactive,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorFg: Color.lerp(errorFg, other.errorFg, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningFg: Color.lerp(warningFg, other.warningFg, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoFg: Color.lerp(infoFg, other.infoFg, t)!,
      surfaceHelp: Color.lerp(surfaceHelp, other.surfaceHelp, t)!,
      canvasBg: Color.lerp(canvasBg, other.canvasBg, t)!,
      canvasInk: Color.lerp(canvasInk, other.canvasInk, t)!,
      statusGreen: Color.lerp(statusGreen, other.statusGreen, t)!,
      statusOrange: Color.lerp(statusOrange, other.statusOrange, t)!,
      statusRed: Color.lerp(statusRed, other.statusRed, t)!,
      statusBlue: Color.lerp(statusBlue, other.statusBlue, t)!,
      statusIndigo: Color.lerp(statusIndigo, other.statusIndigo, t)!,
      statusGrey: Color.lerp(statusGrey, other.statusGrey, t)!,
      statusGreyLight: Color.lerp(statusGreyLight, other.statusGreyLight, t)!,
      progressBg: Color.lerp(progressBg, other.progressBg, t)!,
      navLookup: Color.lerp(navLookup, other.navLookup, t)!,
      navWords: Color.lerp(navWords, other.navWords, t)!,
      navLearn: Color.lerp(navLearn, other.navLearn, t)!,
      navBrowse: Color.lerp(navBrowse, other.navBrowse, t)!,
      navHelp: Color.lerp(navHelp, other.navHelp, t)!,
      coffeeIcon: Color.lerp(coffeeIcon, other.coffeeIcon, t)!,
      coffeeBg: Color.lerp(coffeeBg, other.coffeeBg, t)!,
      coffeeFg: Color.lerp(coffeeFg, other.coffeeFg, t)!,
      linkColor: Color.lerp(linkColor, other.linkColor, t)!,
      tourScrim: Color.lerp(tourScrim, other.tourScrim, t)!,
      dotInactive: Color.lerp(dotInactive, other.dotInactive, t)!,
    );
  }
}

/// Convenience getter so every widget can write `context.appColors.successFg`
/// instead of `Theme.of(context).extension<AppColors>()!`.
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
