import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';

ReviewCard _card(String character, CardType cardType) {
  return ReviewCard(
    character: character,
    cardType: cardType,
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    dueDate: DateTime(2026, 1, 1),
    lapses: 0,
  );
}

void main() {
  group('interleaveByCharacter', () {
    test('empty list stays empty', () {
      expect(interleaveByCharacter([]), isEmpty);
    });

    test('a single character\'s cards are returned unchanged (nothing to '
        'interleave against)', () {
      final cards = [
        _card('一', CardType.drawFromMeaning),
        _card('一', CardType.kanjiRecognition),
      ];
      expect(interleaveByCharacter(cards), cards);
    });

    test(
      'round-robins across characters instead of leaving them clustered -- '
      'two cards each for 一 and 二, introduced back-to-back per character '
      '(as introduceNewCards naturally produces), come out alternating',
      () {
        final cards = [
          _card('一', CardType.drawFromMeaning),
          _card('一', CardType.kanjiRecognition),
          _card('二', CardType.drawFromMeaning),
          _card('二', CardType.kanjiRecognition),
        ];

        final result = interleaveByCharacter(cards);

        expect(result.map((c) => c.character), ['一', '二', '一', '二']);
        // Every original card is still present, just reordered -- same
        // (character, cardType) pairs, no duplicates or drops.
        expect(
          result.map((c) => (c.character, c.cardType)).toSet(),
          cards.map((c) => (c.character, c.cardType)).toSet(),
        );
      },
    );

    test(
      'never places two same-character cards adjacent as long as another '
      'character still has cards left',
      () {
        final cards = [
          _card('一', CardType.drawFromMeaning),
          _card('一', CardType.kanjiRecognition),
          _card('一', CardType.readingCloze),
          _card('二', CardType.drawFromMeaning),
          _card('三', CardType.drawFromMeaning),
        ];

        final result = interleaveByCharacter(cards);

        for (var i = 1; i < result.length; i++) {
          final sameAsPrevious = result[i].character == result[i - 1].character;
          // 一 has 3 cards, 二+三 have 1 each -- by the 4th slot both other
          // characters are exhausted, so a same-character repeat is
          // unavoidable there specifically, but never before that.
          if (sameAsPrevious) {
            expect(i, greaterThanOrEqualTo(4));
          }
        }
      },
    );

    test(
      'characters keep their first-seen order across rounds (stable, not '
      'shuffled) -- makes the output deterministic and easy to reason about',
      () {
        final cards = [
          _card('三', CardType.drawFromMeaning),
          _card('一', CardType.drawFromMeaning),
          _card('二', CardType.drawFromMeaning),
          _card('三', CardType.kanjiRecognition),
          _card('一', CardType.kanjiRecognition),
          _card('二', CardType.kanjiRecognition),
        ];

        final result = interleaveByCharacter(cards);

        expect(result.map((c) => c.character), [
          '三', '一', '二', '三', '一', '二',
        ]);
      },
    );
  });
}
