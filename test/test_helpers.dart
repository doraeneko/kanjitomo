import 'package:flutter/material.dart';
import 'package:kanjitomo/core/theme/app_colors.dart';
import 'package:kanjitomo/l10n/app_localizations.dart';

/// Wraps [home] in a [MaterialApp] with the localization delegates and
/// supported locales required by the app's i18n setup. Use this in tests
/// instead of a bare `MaterialApp(home: ...)` so that
/// `AppLocalizations.of(context)` resolves correctly.
Widget testApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
      extensions: const [AppColors.light],
    ),
    home: home,
  );
}
