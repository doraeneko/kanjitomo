import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_dependencies.dart';
import 'features/home_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  // Portrait only -- every review/edit screen's layout (see
  // review_session_screen.dart's _buildDrawInSentence in particular) is
  // hand-tuned against portrait's aspect ratio, reserving pixel budgets for
  // fixed-size siblings around a variable-height sentence box. None of that
  // has ever been verified in landscape, and there's no reason to expect it
  // would still fit -- locking orientation avoids shipping a broken
  // landscape layout rather than trying to make every screen responsive to
  // both.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  _registerThirdPartyLicenses();
  runApp(const KanjitomoApp());
}

/// Attributes the external dictionary/sentence data this app is built on
/// -- surfaced via the Help screen's "Open source licenses" page
/// (Flutter's own showLicensePage, fed by this registry).
void _registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['JMdict/EDICT'],
      'This application uses the JMdict/EDICT dictionary files. These '
      'files are the property of the Electronic Dictionary Research and '
      'Development Group (EDRDG), and are used in conformance with the '
      "Group's licence (Creative Commons Attribution-ShareAlike 4.0 "
      'International). See https://www.edrdg.org/ for details.',
    );
    yield LicenseEntryWithLineBreaks(
      const ['Tatoeba'],
      'Example sentences are sourced from the Tatoeba Project '
      '(https://tatoeba.org), licensed under CC BY 2.0 FR.',
    );
    yield LicenseEntryWithLineBreaks(
      const ['KANJIDIC2 / KRADFILE-U'],
      'Kanji readings, meanings, and component decomposition data are '
      'sourced from KANJIDIC2 and KRADFILE-U. These files are the '
      'property of the Electronic Dictionary Research and Development '
      "Group (EDRDG), and are used in conformance with the Group's "
      'licence (Creative Commons Attribution-ShareAlike 4.0 '
      'International). See https://www.edrdg.org/ for details.',
    );
    yield LicenseEntryWithLineBreaks(
      const ['KanjiVG'],
      'Stroke order data is sourced from KanjiVG '
      '(https://kanjivg.tagaini.net), created by Ulrich Apel and '
      'licensed under Creative Commons Attribution-ShareAlike 3.0.',
    );
    yield LicenseEntryWithLineBreaks(
      const ['ETL Character Database'],
      'The handwriting recognition model was trained in part on the ETL '
      'Character Database. Electrotechnical Laboratory, Japanese '
      'Technical Committee for Optical Character Recognition, ETL '
      'Character Database, 1973-1984. Property of the National '
      'Institute of Advanced Industrial Science and Technology (AIST). '
      'See https://etlcdb.db.aist.go.jp/ for details.',
    );
  });
}

class KanjitomoApp extends StatelessWidget {
  /// Overridable for tests, which need an in-memory database (the real one
  /// needs path_provider, unavailable in a plain widget test) -- production
  /// always uses the default.
  final AppDependencies? deps;

  const KanjitomoApp({super.key, this.deps});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kanjitomo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _AppStartup(deps: deps ?? AppDependencies()),
    );
  }
}

/// Loads every bundled data asset + syncs the local database once before
/// showing the app -- these are small/fast (JSON parsing, not the ONNX
/// model), so a brief blocking splash is simpler than threading a loading
/// state through every screen that needs this data.
class _AppStartup extends StatefulWidget {
  final AppDependencies deps;

  const _AppStartup({required this.deps});

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.deps
        .load()
        .then((_) {
          if (mounted) setState(() => _loading = false);
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = e.toString();
            });
          }
        });
  }

  @override
  void dispose() {
    widget.deps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final l = AppLocalizations.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l?.failedToLoadAppData(_error!) ?? 'Failed to load app data: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return HomeScreen(deps: widget.deps);
  }
}
