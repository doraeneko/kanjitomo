import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';

/// Minimal about/help screen, and the app's licensing-attribution entry
/// point (JMdict, Tatoeba -- see main.dart's LicenseRegistry.addLicense
/// calls) -- reachable from the main lookup screen's app bar.
class HelpScreen extends StatelessWidget {
  final AppDependencies deps;

  const HelpScreen({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.helpIntro),
            const SizedBox(height: 24),
            Text(l.helpLearningTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l.helpLearningDescription),
            const SizedBox(height: 24),
            Text(l.helpReviewTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l.helpReviewDescription),
            const SizedBox(height: 24),
            ValueListenableBuilder<bool>(
              valueListenable: deps.proStatus.isProUnlocked,
              builder: (context, isPro, _) {
                if (isPro) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => deps.purchaseService.restorePurchases(),
                    child: Text(l.helpRestorePurchases),
                  ),
                );
              },
            ),
            OutlinedButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
              ),
              child: Text(l.helpOpenSourceLicenses),
            ),
          ],
        ),
      ),
    );
  }
}
