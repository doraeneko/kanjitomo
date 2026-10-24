import '../../test_helpers.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/first_time_dialog.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/review_session_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  testWidgets(
    'removing a kanji during review deletes its data, keeps shared '
    'composita of other kanji, and moves on',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load(loadAll: true));
      await deps.studyScope.update(const StudyScope(characters: {'一', '番'}));

      // 一番 is selected for both kanji.
      final repo = ReviewRepository(deps.database);
      await repo.introduceCardsForCharacters(
        {'一', '番'},
        compositaWordsByChar: {'一': ['一番'], '番': ['一番']},
      );
      await repo.addCustomComposita('一', '一番');
      await repo.addCustomComposita('番', '一番');

      // Kanji-recognition-only session: 一 comes first (RTK order).
      await tester.pumpWidget(testApp(
        home: ReviewSessionScreen(
          deps: deps,
          cardTypes: const {CardType.kanjiRecognition},
        ),
      ));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(find.text('Review \u2014 1/2 \u2014 New'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('review-remove-kanji')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('review-remove-kanji-confirm')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // Moved on to 番, the only card left.
      expect(find.text('Review \u2014 1/1 \u2014 New'), findsOneWidget);
      expect(find.text('一 removed from your learning pool'), findsOneWidget);
      expect(deps.studyScope.scope.value.characters, {'番'});

      final db = deps.database;
      final cards = await db.select(db.reviewCards).get();
      expect(cards.where((c) => c.character == '一'), isEmpty);
      expect(
        cards.where((c) => c.character == '番' && c.compositaWord == '一番'),
        hasLength(2),
      );
      expect(await repo.customCompositaFor('一'), isEmpty);
      expect(await repo.customCompositaFor('番'), {'一番'});
    },
  );
}
