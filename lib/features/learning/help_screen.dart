import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_dependencies.dart';
import '../../core/first_time_dialog.dart';
import '../../core/kanji_mascot.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/kanji_recognizer.dart' show ModelVariant;
import '../../widgets/coffee_button.dart';
import '../../main.dart' show kThemePrefKey, kThemeModePrefKey, themeColorNotifier, themeModeNotifier, themePresets;

/// Help & about screen: take the tour, acknowledgements, licenses,
/// restore purchases, and reset help.
class HelpScreen extends StatefulWidget {
  final AppDependencies deps;
  final VoidCallback? onStartTour;

  const HelpScreen({super.key, required this.deps, this.onStartTour});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late ModelVariant _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.deps.recognizer.isReady
        ? widget.deps.recognizer.loadedVariant
        : ModelVariant.standard;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final appColors = context.appColors;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── App Header ──
            Center(child: KanjiMascot(size: 80)),
            const SizedBox(height: 12),
            Text(
              l.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l.helpTagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: appColors.textSecondary,
              ),
            ),
            if (widget.onStartTour != null) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: widget.onStartTour,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(l.welcomeTakeTour),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // ── Feature Highlights ──
            _SectionDivider(label: l.helpFeaturesSection),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.brush,
              title: l.helpFeatureRecognitionTitle,
              description: l.helpFeatureRecognitionDesc,
            ),
            _FeatureCard(
              icon: Icons.event_repeat,
              title: l.helpFeatureSrsTitle,
              description: l.helpFeatureSrsDesc,
            ),
            _FeatureCard(
              icon: Icons.auto_stories,
              title: l.helpFeatureCompositaTitle,
              description: l.helpFeatureCompositaDesc,
            ),
            _FeatureCard(
              icon: Icons.gesture,
              title: l.helpFeatureStrokeOrderTitle,
              description: l.helpFeatureStrokeOrderDesc,
            ),
            _FeatureCard(
              icon: Icons.menu_book,
              title: l.helpFeatureDictionaryTitle,
              description: l.helpFeatureDictionaryDesc,
            ),
            _FeatureCard(
              icon: Icons.edit_note,
              title: l.helpFeatureStoriesTitle,
              description: l.helpFeatureStoriesDesc,
            ),
            const SizedBox(height: 24),
            // ── Settings ──
            _SectionDivider(label: l.helpSettingsSection),
            const SizedBox(height: 12),
            // ── Theme picker ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settingsTheme,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<Color>(
                      valueListenable: themeColorNotifier,
                      builder: (context, currentColor, _) {
                        String themeName(String key) {
                          switch (key) {
                            case 'indigo': return l.themeIndigo;
                            case 'teal': return l.themeTeal;
                            case 'sakura': return l.themeSakura;
                            case 'forest': return l.themeForest;
                            case 'amber': return l.themeAmber;
                            default: return key;
                          }
                        }
                        return Wrap(
                          spacing: 8,
                          children: themePresets.entries.map((e) {
                            final selected = e.value == currentColor;
                            return ChoiceChip(
                              label: Text(themeName(e.key)),
                              selected: selected,
                              avatar: CircleAvatar(
                                backgroundColor: e.value,
                                radius: 8,
                              ),
                              onSelected: (_) async {
                                themeColorNotifier.value = e.value;
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(kThemePrefKey, e.key);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Brightness toggle ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settingsBrightness,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, currentMode, _) {
                        return SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l.themeAuto),
                              icon: const Icon(Icons.brightness_auto),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l.themeLight),
                              icon: const Icon(Icons.light_mode),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l.themeDark),
                              icon: const Icon(Icons.dark_mode),
                            ),
                          ],
                          selected: {currentMode},
                          onSelectionChanged: (selection) async {
                            final mode = selection.first;
                            themeModeNotifier.value = mode;
                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString(
                                kThemeModePrefKey, mode.name);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // ── Recognition model picker ──
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settingsRecognitionModel,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SegmentedButton<ModelVariant>(
                      segments: [
                        ButtonSegment(
                          value: ModelVariant.standard,
                          label: Text(l.modelStandard),
                        ),
                        ButtonSegment(
                          value: ModelVariant.extended,
                          label: Text(l.modelExtended),
                        ),
                      ],
                      selected: {_selectedVariant},
                      onSelectionChanged: (selection) async {
                        final variant = selection.first;
                        if (variant == _selectedVariant) return;
                        setState(() => _selectedVariant = variant);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.modelSwitching)),
                        );
                        try {
                          await widget.deps.switchModel(variant);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l.modelSwitched)),
                            );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _selectedVariant =
                              widget.deps.recognizer.loadedVariant);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(l.modelSwitchFailed(
                                    e.toString())),
                              ),
                            );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Support & Feedback ──
            Card(
              color: appColors.surfaceHelp,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.coffee, size: 36, color: appColors.coffeeIcon),
                    const SizedBox(height: 8),
                    Text(
                      l.helpSupportDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        CoffeeButton.uri,
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.favorite),
                      label: Text(l.helpSupportDevelopment),
                      style: FilledButton.styleFrom(
                        backgroundColor: appColors.coffeeBg,
                        foregroundColor: appColors.coffeeFg,
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
                    Icon(Icons.bug_report, size: 36, color: appColors.statusGrey),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://doraeneko.github.io/kanjitomo/privacy_policy.html'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(l.helpPrivacyPolicy),
            ),
            const SizedBox(height: 24),
            // ── Acknowledgements ──
            const Divider(),
            const SizedBox(height: 12),
            Text(
              l.helpAcknowledgement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors.textSecondary,
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
            _ProjectTile(
              name: 'Google ML Kit',
              description: 'Camera text recognition',
              license: 'Apache 2.0',
              url: 'https://developers.google.com/ml-kit',
              copyright: '© Google',
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
              valueListenable: widget.deps.proStatus.isProUnlocked,
              builder: (context, isPro, _) {
                if (isPro) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => widget.deps.purchaseService.restorePurchases(),
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

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: appColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(description,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
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
    final appColors = context.appColors;
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
                              ? appColors.linkColor
                              : appColors.textTertiary,
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
