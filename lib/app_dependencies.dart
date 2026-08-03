import 'dart:async';

import 'core/db/app_database.dart';
import 'core/kanji_recognizer.dart';
import 'data/composita_repository.dart';
import 'data/jlpt_levels_repository.dart';
import 'data/kanji_info_repository.dart';
import 'data/kanji_level_rank_repository.dart';
import 'data/rtk_index_repository.dart';
import 'data/sentences_repository.dart';
import 'data/stories_repository.dart';
import 'data/stroke_paths_repository.dart';
import 'data/word_index_repository.dart';
import 'features/pro/pro_status_repository.dart';
import 'features/pro/purchase_service.dart';
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
  AppDependencies({AppDatabase? database}) : database = database ?? AppDatabase();

  final AppDatabase database;
  final KanjiRecognizer recognizer = KanjiRecognizer();
  late final Future<void> recognizerReady;
  final KanjiInfoRepository kanjiInfo = KanjiInfoRepository();
  final JlptLevelsRepository jlptLevels = JlptLevelsRepository();
  final RtkIndexRepository rtkIndex = RtkIndexRepository();
  final KanjiLevelRankRepository kanjiLevelRank = KanjiLevelRankRepository();
  final CompositaRepository composita = CompositaRepository();
  final SentencesRepository sentences = SentencesRepository();
  final StoriesRepository stories = StoriesRepository();
  final StrokePathsRepository strokePaths = StrokePathsRepository();
  final WordIndexRepository wordIndex = WordIndexRepository();
  final StudyScopeRepository studyScope = StudyScopeRepository();
  final ProStatusRepository proStatus = ProStatusRepository();
  final PurchaseService purchaseService = PurchaseService();

  /// Loads every bundled JSON asset and syncs the database. Also kicks off
  /// [recognizer.load()] in parallel (without awaiting it) -- ONNX session
  /// creation is the slowest piece and no screen other than lookup/review
  /// needs it, so screens that do can await [recognizerReady] themselves.
  Future<void> load() async {
    // Fire-and-forget: the future's error (if any) is only observed when a
    // screen awaits recognizerReady -- ignore it here so an uncaught async
    // error doesn't surface in environments where path_provider is absent
    // (e.g. plain widget tests that never use the recognizer).
    recognizerReady = recognizer.load();
    recognizerReady.ignore();
    await Future.wait([
      kanjiInfo.load(),
      jlptLevels.load(),
      rtkIndex.load(),
      kanjiLevelRank.load(),
      composita.load(),
      sentences.load(),
      stories.load(),
      strokePaths.load(),
      wordIndex.load(),
      studyScope.load(),
      proStatus.load(),
    ]);
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
    // Fire-and-forget: store connection is not needed for startup and may
    // fail silently in environments without a billing service (tests,
    // desktop). The paywall sheet handles the case where product details
    // haven't loaded yet. Guarded zone absorbs any async platform channel
    // errors that escape the try/catch inside init() itself (the Android
    // billing client's eager connection attempt fires callbacks in a
    // separate microtask).
    runZonedGuarded(
      () => purchaseService.init(proStatus),
      (_, __) {},
    );
  }

  Future<void> dispose() async {
    await purchaseService.dispose();
    await recognizer.dispose();
    await database.close();
  }
}
