import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/kanji_mascot.dart';
import '../l10n/app_localizations.dart';

/// Preference key for whether the welcome screen has been seen.
const welcomeSeenKey = 'ftd.welcome_seen';

/// Full-screen welcome shown on first launch. Pops with `true` if the user
/// chose "Take a tour" (so HomeScreen can start the overlay tour), or pops
/// without a value on skip/dismiss.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _skipTour(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  Future<void> _skipForever(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(welcomeSeenKey, true);
    if (context.mounted) Navigator.of(context).pop(false);
  }

  void _startTour(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KanjiMascot(size: 120),
                const SizedBox(height: 24),
                Text(
                  l.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l.welcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  l.welcomeFeatureList,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startTour(context),
                    child: Text(l.welcomeTakeTour),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _skipTour(context),
                  child: Text(l.welcomeSkip),
                ),
                TextButton(
                  onPressed: () => _skipForever(context),
                  child: Text(l.welcomeDontShowAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data for a single tour step — maps to a bottom-nav tab index.
class TourStep {
  final int tabIndex;
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const TourStep({
    required this.tabIndex,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

List<TourStep> tourSteps(AppLocalizations l) => [
  TourStep(
    tabIndex: 0,
    icon: Icons.brush,
    color: Colors.deepOrange.shade700,
    title: l.ftdLookupTitle,
    message: l.ftdLookupMessage,
  ),
  TourStep(
    tabIndex: 1,
    icon: Icons.text_fields,
    color: Colors.teal.shade700,
    title: l.ftdWordLookupTitle,
    message: l.ftdWordLookupMessage,
  ),
  TourStep(
    tabIndex: 2,
    icon: Icons.school,
    color: Colors.orange.shade700,
    title: l.ftdLearningTitle,
    message: l.ftdLearningMessage,
  ),
  TourStep(
    tabIndex: 3,
    icon: Icons.grid_view,
    color: Colors.indigo.shade700,
    title: l.ftdBrowserTitle,
    message: l.ftdBrowserMessage,
  ),
];
