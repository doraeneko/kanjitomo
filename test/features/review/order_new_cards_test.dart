import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';

ReviewCard _card(String character, CardType cardType, [String word = '']) {
  return ReviewCard(
    character: character,
    cardType: cardType,
    compositaWord: word,
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    dueDate: DateTime(2026, 1, 1),
    lapses: 0,
  );
}

void main() {
  const rtk = {'一': 1, '二': 2, '三': 3, '口': 11};
  int? rtkIndex(String c) => rtk[c];

  final cards = [
    _card('口', CardType.readingCloze, '口調'),
    _card('三', CardType.kanjiRecognition),
    _card('一', CardType.drawInSentence, '一番'),
    _card('一', CardType.drawFromMeaning),
    _card('龍', CardType.drawFromMeaning), // not in RTK index
    _card('二', CardType.kanjiRecognition),
    _card('口', CardType.drawFromMeaning),
  ];

  group('orderNewCards', () {
    test('RTK order sorts by RTK index, unknown kanji last, kanji cards '
        'before composita cards', () {
      final ordered = orderNewCards(cards, NewCardOrder.rtk, rtkIndex: rtkIndex);
      expect(
        ordered.map((c) => '${c.character}:${c.cardType.name}').toList(),
        [
          '一:drawFromMeaning',
          '一:drawInSentence',
          '二:kanjiRecognition',
          '三:kanjiRecognition',
          '口:drawFromMeaning',
          '口:readingCloze',
          '龍:drawFromMeaning',
        ],
      );
    });

    test('random order keeps each kanji\'s cards together, kanji cards '
        'first, and varies with the seed', () {
      final orders = <String>{};
      for (var seed = 0; seed < 10; seed++) {
        final ordered = orderNewCards(
          cards,
          NewCardOrder.random,
          rtkIndex: rtkIndex,
          random: Random(seed),
        );
        expect(ordered, hasLength(cards.length));
        // Each character's cards are contiguous.
        final chars = ordered.map((c) => c.character).toList();
        final seen = <String>{};
        for (var i = 0; i < chars.length; i++) {
          if (i > 0 && chars[i] != chars[i - 1]) {
            expect(seen.contains(chars[i]), isFalse);
          }
          seen.add(chars[i]);
        }
        // Within 一 and 口, the kanji card precedes the composita card.
        for (final ch in ['一', '口']) {
          final types = ordered
              .where((c) => c.character == ch)
              .map((c) => c.compositaWord.isEmpty)
              .toList();
          expect(types, [true, false]);
        }
        orders.add(seen.join());
      }
      expect(orders.length, greaterThan(1));
    });

    test('does not modify the input list', () {
      final copy = [...cards];
      orderNewCards(cards, NewCardOrder.rtk, rtkIndex: rtkIndex);
      expect(cards, copy);
    });
  });
}
