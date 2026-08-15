import 'package:drift/drift.dart';

/// Which skill a review card exercises for a given character. Recognition
/// and production are different skills a learner can be at different
/// mastery levels on, so each is scheduled independently (see
/// [ReviewCards]'s primary key).
///
/// [kanjiRecognition] is appended at the end, not inserted alphabetically --
/// drift's intEnum stores the ordinal index, so appending is the only safe
/// way to add a value without renumbering (and silently corrupting) every
/// already-stored row's cardType.
enum CardType { readingCloze, drawInSentence, drawFromMeaning, kanjiRecognition }

/// Which direction of a composita word's mastery [CompositaProgress] is
/// tracking -- recognizing its reading, or producing (drawing) its target
/// kanji. Mirrors [CardType]'s own recognition/production split, one level
/// down (per word instead of per character).
enum CompositaDirection { reading, writing }

/// SM-2 spaced-repetition state, one row per (character, cardType). See
/// features/review/sm2.dart for the scheduling algorithm that reads/writes
/// these fields -- this table only stores state, no scheduling logic.
class ReviewCards extends Table {
  TextColumn get character => text()();
  IntColumn get cardType => intEnum<CardType>()();
  /// The specific composita word this card tests (readingCloze/drawInSentence
  /// only -- empty string for core card types drawFromMeaning/kanjiRecognition).
  TextColumn get compositaWord => text().withDefault(const Constant(''))();

  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {character, cardType, compositaWord};
}

/// Append-only review history, independent of current [ReviewCards] state --
/// kept for future stats/streaks, not read by the scheduler itself.
class ReviewLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get character => text()();
  IntColumn get cardType => intEnum<CardType>()();
  TextColumn get compositaWord => text().withDefault(const Constant(''))();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get quality => integer()();
  IntColumn get resultingIntervalDays => integer()();
}

/// User-editable personal mnemonic per kanji -- not imported/generated
/// content, the user writes these themselves over time via the app UI.
/// Split into two fields: [storyKeyword] is a short recall cue shown as
/// the pre-draw hint (e.g. in a drawFromMeaning review card, before the
/// answer is known); [story] is the fuller mnemonic, shown only once the
/// answer is already revealed (the kanji editor, or a review miss).
class KanjiNotes extends Table {
  TextColumn get character => text()();
  TextColumn get storyKeyword => text().withDefault(const Constant(''))();
  TextColumn get story => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {character};
}

/// Reference data synced once at startup from the bundled jlpt_levels.json /
/// rtk_index.json assets (idempotent upsert -- see AppDatabase.syncKanjiStatic).
/// Exists so both the kanji browser and the review queue can express the
/// study-scope filter as one real SQL predicate instead of duplicating
/// in-memory filtering logic in two places.
class KanjiStatic extends Table {
  TextColumn get character => text()();
  IntColumn get jlptLevel => integer().nullable()();
  IntColumn get rtkIndex => integer().nullable()();
  // 0-based rank within this character's own JLPT level, sorted by
  // frequency -- powers the "sublevel" chunk filter (e.g. N1's 985 kanji
  // split into groups of 25/50) in StudyScope. See
  // kanjirec/scripts/build_kanji_level_rank.py.
  IntColumn get levelRank => integer().nullable()();

  @override
  Set<Column> get primaryKey => {character};
}

/// Records that a specific composita word has been successfully answered
/// (quality >= 3) at least once in a given [CompositaDirection], for a
/// given character -- one row per (character, word, direction), never
/// deleted once passed. Exists at this finer granularity because a single
/// shared (character, readingCloze/drawInSentence) ReviewCards row can't
/// tell which of a character's several composita/readings was actually
/// tested on any given pass. This is the "C+D" tracking store (composita
/// mastery, both with and without a real example sentence) -- separate
/// from and no longer gating the simple per-character "green" computed in
/// ReviewRepository.overallProgress(), which is A+B (drawFromMeaning +
/// kanjiRecognition) only.
class CompositaProgress extends Table {
  TextColumn get character => text()();
  TextColumn get word => text()();
  IntColumn get direction => intEnum<CompositaDirection>()();
  DateTimeColumn get firstPassedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {character, word, direction};
}

/// A JMdict word manually added by the user as a composita for a given
/// kanji -- words not in the bundled composita.json that the user found
/// via the composita picker's JMdict search or the word lookup screen's
/// "Add to review" button. Merged with the bundled list at review time
/// (see sentence_selection.dart's eligibleComposita) so they're testable
/// just like bundled composita. Converted to [Composita] objects with
/// jlptLevel/inferredJlptLevel null and frequencyRank 1 (high priority).
class UserComposita extends Table {
  TextColumn get character => text()();
  TextColumn get word => text()();
  TextColumn get reading => text()();
  TextColumn get meaning => text()();

  @override
  Set<Column> get primaryKey => {character, word};
}

/// Which composita the user has explicitly attached to a kanji in their
/// Custom composita selection per kanji -- kept as its own table
/// rather than folded into StudyScope's SharedPreferences-backed
/// customCharacters, since it's a growing structured many-to-many relation
/// (many words per character), not a scalar/string-list.
class CustomComposita extends Table {
  TextColumn get character => text()();
  TextColumn get word => text()();

  @override
  Set<Column> get primaryKey => {character, word};
}
