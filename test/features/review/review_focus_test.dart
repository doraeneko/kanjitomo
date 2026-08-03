import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_focus.dart';

void main() {
  group('cardTypesForFocus', () {
    test('core is A+B: drawFromMeaning + kanjiRecognition', () {
      expect(
        cardTypesForFocus(ReviewFocus.core),
        {CardType.drawFromMeaning, CardType.kanjiRecognition},
      );
    });

    test('composita is C+D: readingCloze + drawInSentence', () {
      expect(
        cardTypesForFocus(ReviewFocus.composita),
        {CardType.readingCloze, CardType.drawInSentence},
      );
    });

    test('both is null -- unrestricted, identical to pre-ReviewFocus behavior', () {
      expect(cardTypesForFocus(ReviewFocus.both), isNull);
    });
  });
}
