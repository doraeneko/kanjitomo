import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_dependencies.dart';
import '../../core/first_time_dialog.dart';
import '../../l10n/app_localizations.dart';

/// Help & about screen: take the tour, acknowledgements, licenses,
/// restore purchases, and reset help.
class HelpScreen extends StatelessWidget {
  final AppDependencies deps;
  final VoidCallback? onStartTour;

  const HelpScreen({super.key, required this.deps, this.onStartTour});

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
            const SizedBox(height: 16),
            if (onStartTour != null) ...[
              OutlinedButton.icon(
                onPressed: onStartTour,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l.welcomeTakeTour),
              ),
              const SizedBox(height: 24),
            ],
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.coffee, size: 36, color: Colors.brown),
                    const SizedBox(height: 8),
                    Text(
                      l.helpSupportDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://buymeacoffee.com/kanjitomo'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.favorite),
                      label: Text(l.helpSupportDevelopment),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.bug_report, size: 36, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      l.helpReportBugDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri(
                          scheme: 'mailto',
                          path: 'kanjitomo.feedback@proton.me',
                          queryParameters: {'subject': l.helpBugEmailSubject},
                        ),
                      ),
                      icon: const Icon(Icons.email),
                      label: Text(l.helpReportBug),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              l.helpAcknowledgement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _ProjectTile(
              name: 'JMdict / EDICT',
              description: 'Japanese-English dictionary data',
              license: 'CC BY-SA 4.0',
              url: 'https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project',
              copyright: '© James William Breen and the EDRDG',
            ),
            _ProjectTile(
              name: 'KANJIDIC2 / KRADFILE-U',
              description: 'Kanji readings, meanings & components',
              license: 'CC BY-SA 4.0',
              url: 'https://www.edrdg.org/wiki/index.php/KANJIDIC_Project',
              copyright: '© James William Breen and the EDRDG',
            ),
            _ProjectTile(
              name: 'KanjiVG',
              description: 'Stroke order data',
              license: 'CC BY-SA 3.0',
              url: 'https://kanjivg.tagaini.net/',
              copyright: '© Ulrich Apel',
            ),
            _ProjectTile(
              name: 'Tatoeba',
              description: 'Example sentences',
              license: 'CC BY 2.0 FR',
              url: 'https://tatoeba.org/',
              copyright: '© Tatoeba contributors',
            ),
            _ProjectTile(
              name: 'ETL Character Database',
              description: 'Handwriting recognition training data',
              url: 'https://etlcdb.db.aist.go.jp/',
              copyright: '© AIST',
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
              ),
              child: Text(l.helpOpenSourceLicenses),
            ),
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
              onPressed: () async {
                await resetAllFirstTimeDialogs();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.helpResetTipsDone)),
                );
              },
              child: Text(l.helpResetTips),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final String name;
  final String description;
  final String? license;
  final String? url;
  final String? copyright;

  const _ProjectTile({
    required this.name,
    required this.description,
    this.license,
    this.url,
    this.copyright,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (copyright != null) copyright!,
      if (license != null) 'License: $license',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  \u2022  ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' \u2014 $description'),
                    ],
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: url != null
                          ? () => launchUrl(Uri.parse(url!),
                              mode: LaunchMode.externalApplication)
                          : null,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: url != null
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                          decoration: url != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
