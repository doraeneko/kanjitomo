import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/first_time_dialog.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';
import 'package:kanjitomo/features/review/statistics_screen.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

// Own file: a full AppDependencies load, same "second real asset load in
// the same test process can be unreliable" reasoning as elsewhere in this
// suite (see stroke_order_test_helpers.dart).
void main() {
  testWidgets(
    'learnt counts the kanji alone; complete also needs its composita, '
    'even with the composita ceiling off',
    (tester) async {
      SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
      final deps = AppDependencies(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
      );
      await tester.runAsync(() => deps.load(loadAll: true));
      // No compositaCeiling ("Off"), but a custom composita selection --
      // the review session tests it, so statistics must count it too.
      await deps.studyScope.update(const StudyScope(characters: {'一'}));

      final repo = ReviewRepository(deps.database);
      await repo.addCustomComposita('一', '一番');
      // Two passes each make A and B "known".
      for (var i = 0; i < 2; i++) {
        await repo.gradeCard(
            character: '一', cardType: CardType.kanjiRecognition, quality: 4);
        await repo.gradeCard(
            character: '一', cardType: CardType.drawFromMeaning, quality: 4);
      }

      Future<void> openStats() async {
        await tester.pumpWidget(testApp(
          home: StatisticsScreen(key: UniqueKey(), deps: deps),
        ));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
      }

      await openStats();
      expect(find.text('1 / 1 kanji learnt'), findsOneWidget);
      expect(find.text('0 / 1 complete with composita'), findsOneWidget);

      await repo.recordCompositaTested('一', '一番', CompositaDirection.reading);
      await repo.recordCompositaTested('一', '一番', CompositaDirection.writing);
      await openStats();
      expect(find.text('1 / 1 complete with composita'), findsOneWidget);
    },
  );
}
