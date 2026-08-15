import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/data/composita_repository.dart';
import 'package:kanjitomo/features/review/sentence_selection.dart';
import 'package:kanjitomo/features/review/study_scope.dart';

void main() {
  group('compositaEnabled', () {
    test(
      'requires an explicit compositaCeiling -- null means not opted in yet',
      () {
        expect(
          compositaEnabled(const StudyScope(characters: {'一'})),
          isFalse,
        );
        expect(
          compositaEnabled(
            const StudyScope(characters: {'一'}, compositaCeiling: 3),
          ),
          isTrue,
        );
      },
    );
  });

  group('compositaWithinCeiling', () {
    const n1Real = Composita(
      word: '月並',
      reading: 'つきなみ',
      meaning: 'commonplace',
      jlptLevel: 1,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    const n5Real = Composita(
      word: '並ぶ',
      reading: 'ならぶ',
      meaning: 'to line up',
      jlptLevel: 5,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    const n2Inferred = Composita(
      word: '並用',
      reading: 'へいよう',
      meaning: 'combined use',
      jlptLevel: null,
      inferredJlptLevel: 2,
      frequencyRank: 1,
    );
    const unclassified = Composita(
      word: '並化',
      reading: 'へいか',
      meaning: '(made up, unclassified)',
      jlptLevel: null,
      inferredJlptLevel: null,
      frequencyRank: 4,
    );

    test('no ceiling (null) always passes, regardless of level', () {
      expect(compositaWithinCeiling(n1Real, null), isTrue);
      expect(compositaWithinCeiling(unclassified, null), isTrue);
    });

    test('a word harder than the ceiling is rejected', () {
      expect(compositaWithinCeiling(n1Real, 2), isFalse);
    });

    test('a word at or easier than the ceiling passes', () {
      expect(compositaWithinCeiling(n5Real, 2), isTrue); // N5 easier than N2
      expect(compositaWithinCeiling(n2Inferred, 2), isTrue); // exactly N2
    });

    test('an unclassified word (no real or inferred level) is rejected '
        'whenever a ceiling applies -- unconfirmed is not assumed safe', () {
      expect(compositaWithinCeiling(unclassified, 2), isFalse);
    });
  });

  group('eligibleComposita', () {
    const n1 = Composita(
      word: '一向',
      reading: 'いっこう',
      meaning: 'entirely',
      jlptLevel: 1,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    const n5 = Composita(
      word: '一つ',
      reading: 'ひとつ',
      meaning: 'one (thing)',
      jlptLevel: 5,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );

    test(
      'customSelected non-empty: exactly the explicitly-selected words, '
      'no ceiling fallback',
      () {
        const scope = StudyScope(characters: {'一'});
        expect(eligibleComposita([n1, n5], scope, {'一つ'}), [n5]);
        // Empty customSelected with no ceiling: falls through to
        // ceiling-based filtering; null ceiling means everything passes.
        expect(eligibleComposita([n1, n5], scope, {}), [n1, n5]);
      },
    );

    test('customSelected empty: filtered by compositaCeiling', () {
      const scope = StudyScope(
        characters: {'一'},
        compositaCeiling: 3,
      );
      // 一向 (N1) is excluded since it's harder than the N3 ceiling, while
      // 一つ (N5, easier) passes.
      expect(eligibleComposita([n1, n5], scope, {}), [n5]);
    });

    test('no ceiling and no customSelected: all composita pass', () {
      const scope = StudyScope(characters: {'一'});
      // No ceiling means compositaWithinCeiling always returns true, but
      // customSelected is empty so it falls through to ceiling-based filter.
      expect(eligibleComposita([n1, n5], scope, {}), [n1, n5]);
    });
  });

  group('pickUntested', () {
    const first = Composita(
      word: '一',
      reading: 'いち',
      meaning: 'one',
      jlptLevel: 5,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    const second = Composita(
      word: '一つ',
      reading: 'ひとつ',
      meaning: 'one (thing)',
      jlptLevel: 5,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    const third = Composita(
      word: '一部',
      reading: 'いちぶ',
      meaning: 'a part',
      jlptLevel: 4,
      inferredJlptLevel: null,
      frequencyRank: 2,
    );

    test('null when there is nothing eligible', () {
      expect(pickUntested(const [], const {}), isNull);
    });

    test('the first entry when nothing has been tested yet', () {
      expect(pickUntested([first, second], const {}), first);
    });

    test('the first NOT-YET-tested entry, skipping ones already covered', () {
      expect(pickUntested([first, second, third], {'一'}), second);
    });

    test('falls back to a random entry once everything is tested', () {
      final result = pickUntested([first, second], {'一', '一つ'});
      expect(result, anyOf(first, second));
    });
  });

  group('syntheticSentenceFor', () {
    test(
      'builds a single-token pseudo-sentence carrying the word itself as '
      'both surface and reading target, and its meaning as the '
      "translation -- so C (composita testing without a real mined "
      "sentence) can run through the same FuriganaSentence-based card "
      'builders as D',
      () {
        const composita = Composita(
          word: '一向',
          reading: 'いっこう',
          meaning: 'entirely, not at all',
          jlptLevel: 2,
          inferredJlptLevel: null,
          frequencyRank: 1,
        );

        final sentence = syntheticSentenceFor(composita);

        expect(sentence.sentence, '一向');
        expect(sentence.tokens, hasLength(1));
        expect(sentence.tokens.single.surface, '一向');
        expect(sentence.tokens.single.reading, 'いっこう');
        expect(sentence.tokens.single.isTarget, isTrue);
        expect(sentence.jlptLevel, 2);
        expect(sentence.source, 'synthetic');
        expect(sentence.translation, 'entirely, not at all');
      },
    );

    test(
      'falls back to the kanji-inferred level, then N5, when the word has '
      'no real JLPT tag of its own',
      () {
        const inferred = Composita(
          word: '並用',
          reading: 'へいよう',
          meaning: 'combined use',
          jlptLevel: null,
          inferredJlptLevel: 2,
          frequencyRank: 1,
        );
        const unclassified = Composita(
          word: '並化',
          reading: 'へいか',
          meaning: '(made up, unclassified)',
          jlptLevel: null,
          inferredJlptLevel: null,
          frequencyRank: 4,
        );

        expect(syntheticSentenceFor(inferred).jlptLevel, 2);
        expect(syntheticSentenceFor(unclassified).jlptLevel, 5);
      },
    );
  });
}
