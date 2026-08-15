import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';

// Own file, not grouped with other review-session tests: confirmed
// elsewhere in this suite that a second runAsync-wrapped real asset load in
// the same test *process* can hang, so each test needing a full
// AppDependencies load gets its own file.
void main() {
  test(
    'introduceCardsForCharacters creates A+B without composita, '
    'and A+B+C+D when compositaWordsByChar is provided',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final reviewRepo = ReviewRepository(db);

      // Introduce A+B only (no composita words).
      await reviewRepo.introduceCardsForCharacters({'一'});

      var cards = await db.select(db.reviewCards).get();
      expect(cards.map((c) => c.cardType).toSet(), {
        CardType.kanjiRecognition,
        CardType.drawFromMeaning,
      });

      // Now introduce again WITH composita words -- insertOrIgnore keeps
      // the existing A+B rows, and adds C+D for the composita word.
      await reviewRepo.introduceCardsForCharacters(
        {'一'},
        compositaWordsByChar: {
          '一': ['一応'],
        },
      );

      cards = await db.select(db.reviewCards).get();
      expect(cards.map((c) => c.cardType).toSet(), {
        CardType.drawFromMeaning,
        CardType.kanjiRecognition,
        CardType.readingCloze,
        CardType.drawInSentence,
      });

      // Verify the composita word is set on the C+D cards.
      final compositaCards = cards
          .where((c) =>
              c.cardType == CardType.readingCloze ||
              c.cardType == CardType.drawInSentence)
          .toList();
      for (final card in compositaCards) {
        expect(card.compositaWord, '一応');
      }

      await db.close();
    },
  );
}
