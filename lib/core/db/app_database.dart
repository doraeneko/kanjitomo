import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ReviewCards,
    ReviewLog,
    KanjiNotes,
    KanjiStatic,
    CompositaProgress,
    CustomComposita,
    UserComposita,
    UserSentences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kanjitomo'));

  /// For unit tests: pass an in-memory executor (e.g. `NativeDatabase.memory()`)
  /// instead of opening a real file on disk.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(kanjiStatic, kanjiStatic.levelRank);
      }
      if (from < 3) {
        await m.addColumn(kanjiNotes, kanjiNotes.storyKeyword);
      }
      if (from < 4) {
        // storyKeyword didn't exist before v3, so every row seeded (or
        // written) before that has the old combined "keyword: story" text
        // sitting entirely in `story` -- split it now that there's
        // somewhere for the keyword to go.
        await repairLegacyStorySplit();
      }
      if (from < 5) {
        await m.createTable(compositaProgress);
      }
      if (from < 6) {
        // composita_progress's primary key itself changed (character, word)
        // -> (character, word, direction), which SQLite can't express as a
        // plain addColumn -- drop and recreate rather than hand-write a
        // copy-and-migrate for what's pre-release, easily-relearned review
        // progress (not the core scheduling state in review_cards, which
        // is untouched).
        await m.deleteTable('composita_progress');
        await m.createTable(compositaProgress);
        await m.createTable(customComposita);
      }
      if (from < 7) {
        await m.createTable(userComposita);
      }
      if (from < 8) {
        await _migrateToPerCompositaCards(m);
      }
      if (from < 9) {
        await m.createTable(userSentences);
      }
    },
  );

  /// Rebuilds review_cards with the new 3-column primary key
  /// (character, cardType, compositaWord) and adds compositaWord to
  /// review_log. Composita card types (readingCloze=0, drawInSentence=1)
  /// are dropped since they had no word stored -- they'll be re-introduced
  /// by the session's introduceNewCompositaCards on next review.
  Future<void> _migrateToPerCompositaCards(Migrator m) async {
    // 1. Rebuild review_cards with new PK
    await customStatement('''
      CREATE TABLE review_cards_v8 (
        character TEXT NOT NULL,
        card_type INTEGER NOT NULL,
        composita_word TEXT NOT NULL DEFAULT '',
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER NOT NULL,
        last_reviewed_at INTEGER,
        lapses INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (character, card_type, composita_word)
      )
    ''');
    // Copy only core cards (drawFromMeaning=2, kanjiRecognition=3)
    await customStatement('''
      INSERT INTO review_cards_v8
        (character, card_type, composita_word, ease_factor, interval_days,
         repetitions, due_date, last_reviewed_at, lapses)
      SELECT character, card_type, '', ease_factor, interval_days,
             repetitions, due_date, last_reviewed_at, lapses
      FROM review_cards
      WHERE card_type IN (2, 3)
    ''');
    await customStatement('DROP TABLE review_cards');
    await customStatement('ALTER TABLE review_cards_v8 RENAME TO review_cards');

    // 2. Add compositaWord column to review_log
    await customStatement(
      "ALTER TABLE review_log ADD COLUMN composita_word TEXT NOT NULL DEFAULT ''",
    );
  }

  /// Idempotent upsert of reference data from the bundled jlpt_levels.json /
  /// rtk_index.json / kanji_level_rank.json assets, run once at app
  /// startup. [rtkIndex]/[levelRank] default to empty until their
  /// respective data pipelines exist -- rows just carry a null value until
  /// that's wired in.
  Future<void> syncKanjiStatic({
    required Map<String, int> jlptLevels,
    Map<String, int> rtkIndex = const {},
    Map<String, int> levelRank = const {},
  }) async {
    final characters = {...jlptLevels.keys, ...rtkIndex.keys, ...levelRank.keys};
    await batch((b) {
      b.insertAllOnConflictUpdate(
        kanjiStatic,
        characters.map(
          (char) => KanjiStaticCompanion.insert(
            character: char,
            jlptLevel: Value(jlptLevels[char]),
            rtkIndex: Value(rtkIndex[char]),
            levelRank: Value(levelRank[char]),
          ),
        ),
      );
    });
  }

  /// Seeds kanji_notes' keyword/story from the bundled stories.json, but
  /// only for characters with NO row yet (insertOrIgnore, not upsert) --
  /// unlike syncKanjiStatic's reference data, a story is user-editable
  /// content, so a character the user has already touched (whether by
  /// editing their own keyword/story or by an earlier run of this same
  /// seeding) must never be overwritten back to the bundled default.
  Future<void> seedStories(
    Map<String, ({String keyword, String story})> stories,
  ) async {
    await batch((b) {
      b.insertAll(
        kanjiNotes,
        stories.entries.map(
          (e) => KanjiNotesCompanion.insert(
            character: e.key,
            storyKeyword: Value(e.value.keyword),
            story: Value(e.value.story),
          ),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// One-time repair for kanji_notes rows written before the keyword/story
  /// split (schema v3 introduced storyKeyword): if a row's storyKeyword is
  /// still empty but its story looks like the old combined
  /// "keyword: story" text, split it on the first colon now that there's
  /// somewhere for the keyword to go. Never touches a row that already has
  /// a keyword -- whether from an earlier run of this same repair, or the
  /// user's own edit -- so it's safe to call more than once. Public (not
  /// just migration-internal) so it's directly testable without having to
  /// simulate a full schema upgrade.
  Future<void> repairLegacyStorySplit() async {
    final rows = await select(kanjiNotes).get();
    for (final row in rows) {
      if (row.storyKeyword.isNotEmpty) continue;
      final colon = row.story.indexOf(':');
      if (colon < 0) continue;
      final keyword = row.story.substring(0, colon).trim();
      final story = row.story.substring(colon + 1).trim();
      await (update(
        kanjiNotes,
      )..where((t) => t.character.equals(row.character))).write(
        KanjiNotesCompanion(
          storyKeyword: Value(keyword),
          story: Value(story),
        ),
      );
    }
  }
}
