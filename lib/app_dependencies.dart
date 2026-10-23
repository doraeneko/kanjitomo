import 'dart:async';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/db/app_database.dart';
import 'core/db/tables.dart' show CardType;
import 'core/kanji_recognizer.dart';
import 'main.dart' show kModelVariantPrefKey;
import 'data/composita_repository.dart';
import 'data/jlpt_levels_repository.dart';
import 'data/kanji_info_repository.dart';
import 'data/reading_frequency_repository.dart';
import 'data/kanji_level_rank_repository.dart';
import 'data/rtk_index_repository.dart';
import 'data/sentences_repository.dart';
import 'data/stories_repository.dart';
import 'data/stroke_paths_repository.dart';
import 'data/word_index_repository.dart';
import 'features/pro/pro_status_repository.dart';
import 'features/pro/purchase_service.dart';
import 'features/review/review_repository.dart';
import 'features/review/sentence_selection.dart'
    show selectCompositaForIntroduction, compositaWithinCeiling, isKanji;
import 'features/review/study_scope.dart';

/// Shared, app-wide instances -- created once in main() and passed down via
/// constructors rather than a DI framework, matching the rest of this
/// codebase's plain-Dart style. Owns the one-time startup work: loading
/// every bundled JSON asset in parallel and syncing kanji_static from it.
class AppDependencies {
  /// Defaults to a real on-disk database; tests pass
  /// AppDatabase.forTesting(NativeDatabase.memory()) instead, since the
  /// real one needs path_provider, which has no platform implementation in
  /// a plain widget test.
  AppDependencies({AppDatabase? database})
      : database = database ?? AppDatabase(),
        _skipPurchaseInit = database != null;

  final AppDatabase database;
  final bool _skipPurchaseInit;
  final KanjiRecognizer recognizer = KanjiRecognizer();
  late Future<void> recognizerReady;
  final KanjiInfoRepository kanjiInfo = KanjiInfoRepository();
  final JlptLevelsRepository jlptLevels = JlptLevelsRepository();
  final RtkIndexRepository rtkIndex = RtkIndexRepository();
  final KanjiLevelRankRepository kanjiLevelRank = KanjiLevelRankRepository();
  final CompositaRepository composita = CompositaRepository();
  final SentencesRepository sentences = SentencesRepository();
  final StoriesRepository stories = StoriesRepository();
  final StrokePathsRepository strokePaths = StrokePathsRepository();
  final WordIndexRepository wordIndex = WordIndexRepository();
  final ReadingFrequencyRepository readingFrequency = ReadingFrequencyRepository();
  late final StudyScopeRepository studyScope = StudyScopeRepository(database);
  final ProStatusRepository proStatus = ProStatusRepository();
  final PurchaseService purchaseService = PurchaseService();

  // Bump this whenever bundled JSON assets change so syncKanjiStatic /
  // seedStories re-run. On a fresh install the version is absent, so the
  // seed always runs the first time.
  static const _dataVersion = 4;
  static const _dataVersionKey = 'app.data_version';

  /// Loads every bundled JSON asset and syncs the database. Also kicks off
  /// [recognizer.load()] in parallel (without awaiting it) -- ONNX session
  /// creation is the slowest piece and no screen other than lookup/review
  /// needs it, so screens that do can await [recognizerReady] themselves.
  /// Loads critical-path assets at startup. The 5 largest JSON assets
  /// (composita, sentences, word_index, stroke_paths, reading_frequency)
  /// are deferred and loaded on first access via [ensureComposita] etc.
  ///
  /// Pass [loadAll] = true to eagerly load everything (used by tests that
  /// interact with composita/sentence data without navigating screens).
  Future<void> load({bool loadAll = false}) async {
    // Fire-and-forget: the future's error (if any) is only observed when a
    // screen awaits recognizerReady -- ignore it here so an uncaught async
    // error doesn't surface in environments where path_provider is absent
    // (e.g. plain widget tests that never use the recognizer).
    final prefs = await SharedPreferences.getInstance();
    final variantName = prefs.getString(kModelVariantPrefKey);
    final variant = ModelVariant.values.where((v) => v.name == variantName).firstOrNull
        ?? ModelVariant.standard;
    recognizerReady = recognizer.load(variant: variant);
    recognizerReady.ignore();
    await Future.wait([
      kanjiInfo.load(),
      jlptLevels.load(),
      rtkIndex.load(),
      kanjiLevelRank.load(),
      stories.load(),
      proStatus.load(),
      if (loadAll) ...[
        composita.load(),
        sentences.load(),
        strokePaths.load(),
        wordIndex.load(),
        readingFrequency.load(),
      ],
    ]);

    // StudyScope needs jlptLevels for the legacy JLPT→unified migration,
    // so it must run after the parallel loads complete.
    await studyScope.load(charsInLevels: jlptLevels.charsInLevels);

    // Only run the heavy DB seed / sync when the data version changed (or
    // on first install). This skips ~4000 row upserts on every subsequent
    // cold start, saving several hundred ms on mid-range devices.
    final seeded = prefs.getInt(_dataVersionKey) ?? 0;
    if (seeded < _dataVersion) {
      await database.syncKanjiStatic(
        jlptLevels: jlptLevels.all,
        rtkIndex: rtkIndex.all,
        levelRank: kanjiLevelRank.all,
      );
      await database.seedStories(
        stories.all.map(
          (char, seed) => MapEntry(char, (keyword: seed.keyword, story: seed.story)),
        ),
      );
      await prefs.setInt(_dataVersionKey, _dataVersion);
    }
    // One-time composita rescan: awaited so it finishes before the user
    // interacts (avoids DB contention). The batched implementation yields
    // between chunks to prevent ANR.
    if (!(prefs.getBool('composita_rescan_v6') ?? false)) {
      await _rescanCompositaSelections();
      await prefs.setBool('composita_rescan_v6', true);
    }
    // Fire-and-forget: store connection is not needed for startup and may
    // fail silently in environments without a billing service (tests,
    // desktop). The paywall sheet handles the case where product details
    // haven't loaded yet. Skipped entirely when a test database was
    // provided -- InAppPurchase.instance eagerly starts a platform-channel
    // billing-client connection whose async callbacks escape
    // runZonedGuarded (they're dispatched on the root zone), which causes
    // spurious "test failed after it had already completed" failures.
    if (!_skipPurchaseInit) {
      runZonedGuarded(
        () => purchaseService.init(proStatus),
        (_, __) {},
      );
    }
  }

  /// Switches to a different recognition model variant, persisting the
  /// choice and reloading the ONNX session. Callers should await the
  /// returned future before issuing new predictions.
  Future<void> switchModel(ModelVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kModelVariantPrefKey, variant.name);
    recognizerReady = recognizer.load(variant: variant);
    await recognizerReady;
  }

  // ── One-time composita rescan (v3) ───────────────────────────────────
  // Re-runs selectCompositaForIntroduction for every character that already
  // has custom_composita rows, additively inserting any newly selected words
  // (e.g. rendaku words that the old selection logic missed). Never removes
  // existing selections -- preserves SM-2 progress and manual picks.
  Future<void> _rescanCompositaSelections() async {
    await ensureComposita();
    final scope = studyScope.scope.value;
    if (scope.compositaCeiling == null) return; // composita not enabled

    final repo = ReviewRepository(database);

    // All characters that already have custom_composita rows.
    final allCustom = await repo.customCompositaForCharacters(
      scope.characters,
    );
    // Also include characters with NO composita yet (added with ceiling OFF
    // or a ceiling that had no eligible words). These need initial selection.
    for (final char in scope.characters) {
      allCustom.putIfAbsent(char, () => <String>{});
    }

    final ceiling = scope.compositaCeiling;
    final limit = scope.maxCompositaPerKanji;
    final now = DateTime.now();

    // Process in small batches to avoid ANR on the main thread.
    final entries = allCustom.entries.toList();
    const batchSize = 10;
    for (var start = 0; start < entries.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, entries.length);
      final chunk = entries.sublist(start, end);

      await database.batch((b) {
        for (final entry in chunk) {
          final char = entry.key;
          final existingWords = entry.value;

          final bundled = composita.lookup(char);
          final charLevel = jlptLevels.levelOf(char);
          final eligible = bundled.where((c) {
            if (!c.word.runes.any((r) => isKanji(r))) return false;
            return compositaWithinCeiling(c, ceiling,
                charJlptLevel: charLevel);
          }).toList();
          if (eligible.isEmpty) return;

          final selected = selectCompositaForIntroduction(
            char,
            eligible,
            limit,
            kanjiInfo: kanjiInfo.lookup(char),
          );

          for (final c in selected) {
            if (existingWords.contains(c.word)) continue;

            b.insert(
              database.customComposita,
              CustomCompositaCompanion.insert(
                character: char,
                word: c.word,
              ),
              mode: InsertMode.insertOrIgnore,
            );

            for (final ct in [CardType.readingCloze, CardType.drawInSentence]) {
              b.insert(
                database.reviewCards,
                ReviewCardsCompanion.insert(
                  character: char,
                  cardType: ct,
                  compositaWord: Value(c.word),
                  dueDate: now,
                ),
                mode: InsertMode.insertOrIgnore,
              );
            }
          }
        }
      });
      // Yield to the event loop between batches so the UI stays responsive.
      await Future<void>.delayed(Duration.zero);
    }
  }

  // ── Deferred (lazy) asset loading ─────────────────────────────────────
  // The 5 biggest JSON assets (composita 22MB, sentences 17MB,
  // word_index 35MB, stroke_paths 3.4MB, reading_frequency 2.6MB) are
  // NOT loaded at startup. Each is loaded on first access via a
  // Completer so concurrent callers share the same in-flight future.

  Completer<void>? _compositaCompleter;
  Future<void> ensureComposita() {
    if (composita.isLoaded) return Future.value();
    _compositaCompleter ??= Completer()..complete(composita.load());
    return _compositaCompleter!.future;
  }

  Completer<void>? _sentencesCompleter;
  Future<void> ensureSentences() {
    if (sentences.isLoaded) return Future.value();
    _sentencesCompleter ??= Completer()..complete(sentences.load());
    return _sentencesCompleter!.future;
  }

  Completer<void>? _strokePathsCompleter;
  Future<void> ensureStrokePaths() {
    if (strokePaths.isLoaded) return Future.value();
    _strokePathsCompleter ??= Completer()..complete(strokePaths.load());
    return _strokePathsCompleter!.future;
  }

  Completer<void>? _wordIndexCompleter;
  Future<void> ensureWordIndex() {
    if (wordIndex.isLoaded) return Future.value();
    _wordIndexCompleter ??= Completer()..complete(wordIndex.load());
    return _wordIndexCompleter!.future;
  }

  Completer<void>? _readingFrequencyCompleter;
  Future<void> ensureReadingFrequency() {
    if (readingFrequency.isLoaded) return Future.value();
    _readingFrequencyCompleter ??= Completer()..complete(readingFrequency.load());
    return _readingFrequencyCompleter!.future;
  }

  /// Composita + sentences + strokePaths + readingFrequency — everything
  /// the kanji detail sheet needs.
  Future<void> ensureDetailData() => Future.wait([
    ensureComposita(),
    ensureSentences(),
    ensureStrokePaths(),
    ensureReadingFrequency(),
  ]);

  /// StrokePaths only — for kanji browser sort/filter by stroke count.
  Future<void> ensureBrowserData() => ensureStrokePaths();

  /// Composita + sentences — for review and quiz sessions.
  Future<void> ensureReviewData() => Future.wait([
    ensureComposita(),
    ensureSentences(),
  ]);

  Future<void> dispose() async {
    await purchaseService.dispose();
    await recognizer.dispose();
    await database.close();
  }
}
