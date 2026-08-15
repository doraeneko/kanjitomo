import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Shows a one-time informational dialog the first time the user opens a
/// section of the app. Once dismissed, it never appears again (tracked via
/// a [SharedPreferences] boolean flag keyed by [prefKey]).
///
/// Call from `initState` via `addPostFrameCallback` so the dialog appears
/// after the first frame is rendered.
Future<void> showFirstTimeDialog(
  BuildContext context, {
  required String prefKey,
  required String title,
  required String message,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(prefKey) == true) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx)?.ftdGotIt ?? 'Got it'),
        ),
      ],
    ),
  );

  await prefs.setBool(prefKey, true);
}

/// Prefix for all first-time dialog keys.
const ftdPrefix = 'ftd.';

/// All first-time dialog preference keys (for the "Reset tips" feature).
const ftdKeys = [
  '${ftdPrefix}lookup',
  '${ftdPrefix}word_lookup',
  '${ftdPrefix}learning',
  '${ftdPrefix}browser',
  '${ftdPrefix}review_session',
  '${ftdPrefix}welcome_seen',
];

/// Pre-set values that suppress all first-time dialogs. Merge this into
/// `SharedPreferences.setMockInitialValues(...)` in widget tests to prevent
/// dialogs from blocking interactions.
final Map<String, Object> ftdSuppressedPrefs = {
  for (final key in ftdKeys) key: true,
};

/// Clears all first-time dialog flags so they show again.
Future<void> resetAllFirstTimeDialogs() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in ftdKeys) {
    await prefs.remove(key);
  }
}
