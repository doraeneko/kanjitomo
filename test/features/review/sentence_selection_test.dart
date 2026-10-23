import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/data/composita_repository.dart';
import 'package:kanjitomo/data/kanji_info_repository.dart';
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
      zipfFreq: 3.0,
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

    test('an inferred word with low zipfFreq is rejected even if its '
        'inferred level is within the ceiling', () {
      const rare = Composita(
        word: '言い募る',
        reading: 'いいつのる',
        meaning: 'to speak passionately',
        jlptLevel: null,
        inferredJlptLevel: 2,
        frequencyRank: 3,
        zipfFreq: 1.58,
      );
      expect(compositaWithinCeiling(rare, 2), isFalse);
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

  group('compositaWithinCeiling — frequencyRank filtering', () {
    test('frequencyRank >= 4 words rejected even with high zipfFreq and valid '
        'inferredJlptLevel (the 小肌 bug)', () {
      const kohada = Composita(
        word: '小肌',
        reading: 'こはだ',
        meaning: 'gizzard shad',
        jlptLevel: null,
        inferredJlptLevel: 4,
        frequencyRank: 4,
        zipfFreq: 3.5,
      );
      expect(compositaWithinCeiling(kohada, 5), isFalse);
    });

    test('frequencyRank < 4 words with adequate zipfFreq and valid inferred '
        'level pass', () {
      const common = Composita(
        word: '並行',
        reading: 'へいこう',
        meaning: 'parallel',
        jlptLevel: null,
        inferredJlptLevel: 3,
        frequencyRank: 2,
        zipfFreq: 3.5,
      );
      expect(compositaWithinCeiling(common, 3), isTrue);
    });
  });

  group('kanjiReadingIn', () {
    test('uses pre-computed splits when available', () {
      const c = Composita(
        word: '食堂',
        reading: 'しょくどう',
        meaning: 'cafeteria',
        jlptLevel: 4,
        inferredJlptLevel: null,
        frequencyRank: 1,
        splits: ['しょく', 'どう'],
      );
      expect(kanjiReadingIn('食', c), 'しょく');
      expect(kanjiReadingIn('堂', c), 'どう');
    });

    test('falls back to even-split among kanji when no splits', () {
      const c = Composita(
        word: '食堂',
        reading: 'しょくどう',
        meaning: 'cafeteria',
        jlptLevel: 4,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      // 5 reading chars split evenly among 2 kanji: 食→しょく(3), 堂→どう(2)
      // (rounding: 0*2.5=0..1*2.5=3 for first, 3..5 for second)
      expect(kanjiReadingIn('食', c), 'しょく');
      expect(kanjiReadingIn('堂', c), 'どう');
    });

    test('strips trailing okurigana before splitting', () {
      const c = Composita(
        word: '食べる',
        reading: 'たべる',
        meaning: 'to eat',
        jlptLevel: 5,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      // 'べる' at end of word matches 'べる' at end of reading → stripped,
      // leaving 'た' for the single kanji 食.
      expect(kanjiReadingIn('食', c), 'た');
    });

    test('returns full reading when char not found', () {
      const c = Composita(
        word: '食堂',
        reading: 'しょくどう',
        meaning: 'cafeteria',
        jlptLevel: 4,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      expect(kanjiReadingIn('月', c), 'しょくどう');
    });
  });

  group('selectCompositaForIntroduction', () {
    // Helper to build a Composita with minimal boilerplate.
    Composita c(
      String word,
      String reading, {
      double zipfFreq = 3.0,
      List<String>? splits,
    }) =>
        Composita(
          word: word,
          reading: reading,
          meaning: 'test',
          jlptLevel: null,
          inferredJlptLevel: null,
          frequencyRank: 1,
          zipfFreq: zipfFreq,
          splits: splits,
        );

    test('deduplicates by word, keeping first (highest-frequency) entry', () {
      final eligible = [
        c('食堂', 'しょくどう', zipfFreq: 4.0, splits: ['しょく', 'どう']),
        c('食堂', 'じきどう', zipfFreq: 2.0, splits: ['じき', 'どう']),
        c('食事', 'しょくじ', zipfFreq: 3.5, splits: ['しょく', 'じ']),
      ];
      final result = selectCompositaForIntroduction('食', eligible, 10);
      // Only one 食堂 should remain.
      expect(result.where((r) => r.word == '食堂').length, 1);
      expect(result.first.reading, 'しょくどう'); // higher zipfFreq kept
    });

    test('returns all when eligible.length <= limit', () {
      final eligible = [
        c('食堂', 'しょくどう', splits: ['しょく', 'どう']),
        c('食事', 'しょくじ', splits: ['しょく', 'じ']),
      ];
      final result = selectCompositaForIntroduction('食', eligible, 10);
      expect(result, hasLength(2));
    });

    test('greedy first pass covers distinct readings via kanjiInfo on/kun', () {
      const info = KanjiInfo(
        on: ['ショク', 'ジキ'],
        kun: ['た.べる', 'く.う'],
        meanings: ['eat'],
        radicals: [],
      );
      final eligible = [
        c('食堂', 'しょくどう', zipfFreq: 5.0, splits: ['しょく', 'どう']),
        c('食事', 'しょくじ', zipfFreq: 4.5, splits: ['しょく', 'じ']),
        c('食べる', 'たべる', zipfFreq: 4.0, splits: ['た', 'べる']),
        c('食う', 'くう', zipfFreq: 3.5, splits: ['く', 'う']),
        c('食料', 'しょくりょう', zipfFreq: 3.0, splits: ['しょく', 'りょう']),
        c('食品', 'しょくひん', zipfFreq: 2.5, splits: ['しょく', 'ひん']),
      ];
      // With limit 3: first pass should pick one per distinct reading,
      // then fill remaining from frequency.
      final result = selectCompositaForIntroduction(
        '食',
        eligible,
        3,
        kanjiInfo: info,
      );
      expect(result, hasLength(3));
      // Should include at least しょく and one other reading.
      final readings = result.map((r) => kanjiReadingIn('食', r)).toSet();
      expect(readings.length, greaterThan(1));
    });

    test('second pass fills remaining slots by frequency', () {
      const info = KanjiInfo(
        on: ['ショク'],
        kun: ['た.べる'],
        meanings: ['eat'],
        radicals: [],
      );
      final eligible = [
        c('食堂', 'しょくどう', zipfFreq: 5.0, splits: ['しょく', 'どう']),
        c('食事', 'しょくじ', zipfFreq: 4.5, splits: ['しょく', 'じ']),
        c('食べる', 'たべる', zipfFreq: 4.0, splits: ['た', 'べる']),
        c('食料', 'しょくりょう', zipfFreq: 3.0, splits: ['しょく', 'りょう']),
        c('食品', 'しょくひん', zipfFreq: 2.5, splits: ['しょく', 'ひん']),
      ];
      final result = selectCompositaForIntroduction(
        '食',
        eligible,
        4,
        kanjiInfo: info,
      );
      expect(result, hasLength(4));
      // The first two (by frequency) after the diversity pass should be
      // filled from remaining highest-frequency words.
    });

    test('returns results in frequency order', () {
      const info = KanjiInfo(
        on: ['ショク'],
        kun: ['た.べる'],
        meanings: ['eat'],
        radicals: [],
      );
      final eligible = [
        c('食堂', 'しょくどう', zipfFreq: 5.0, splits: ['しょく', 'どう']),
        c('食べる', 'たべる', zipfFreq: 4.0, splits: ['た', 'べる']),
        c('食事', 'しょくじ', zipfFreq: 4.5, splits: ['しょく', 'じ']),
        c('食料', 'しょくりょう', zipfFreq: 3.0, splits: ['しょく', 'りょう']),
      ];
      final result = selectCompositaForIntroduction(
        '食',
        eligible,
        3,
        kanjiInfo: info,
      );
      // Verify descending zipfFreq order (since the function sorts internally).
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].zipfFreq,
          lessThanOrEqualTo(result[i - 1].zipfFreq),
          reason: 'results should be in frequency (descending zipfFreq) order',
        );
      }
    });

    test('diversity pass picks one word per distinct reading even if that '
        'reading appears in only one word', () {
      const info = KanjiInfo(
        on: ['ショク', 'ジキ'],
        kun: ['た.べる'],
        meanings: ['eat'],
        radicals: [],
      );
      final eligible = [
        c('食堂', 'しょくどう', zipfFreq: 5.0, splits: ['しょく', 'どう']),
        c('食事', 'しょくじ', zipfFreq: 4.5, splits: ['しょく', 'じ']),
        c('食料', 'しょくりょう', zipfFreq: 4.0, splits: ['しょく', 'りょう']),
        // じき reading appears in only one word — should still be picked
        // by diversity pass to cover the ジキ on'yomi.
        c('食器', 'じきき', zipfFreq: 3.5, splits: ['じき', 'き']),
        c('食べる', 'たべる', zipfFreq: 3.0, splits: ['た', 'べる']),
      ];
      final result = selectCompositaForIntroduction(
        '食',
        eligible,
        3,
        kanjiInfo: info,
      );
      expect(result, hasLength(3));
      // All three distinct readings should be covered.
      final readings = result.map((r) => kanjiReadingIn('食', r)).toSet();
      expect(readings, containsAll(['しょく', 'じき', 'た']));
    });

    test('handles rendaku variants (e.g. はい → ぱい for 失敗)', () {
      const info = KanjiInfo(
        on: ['ハイ'],
        kun: ['やぶ.れる'],
        meanings: ['failure'],
        radicals: [],
      );
      final eligible = [
        c('失敗', 'しっぱい', zipfFreq: 5.0, splits: ['しっ', 'ぱい']),
        c('敗北', 'はいぼく', zipfFreq: 4.0, splits: ['はい', 'ぼく']),
        c('敗退', 'はいたい', zipfFreq: 3.5, splits: ['はい', 'たい']),
      ];
      final result = selectCompositaForIntroduction(
        '敗',
        eligible,
        3,
        kanjiInfo: info,
      );
      // 失敗's reading ぱい should be recognized as a rendaku variant of はい,
      // so it shouldn't be rejected as jukujikun.
      expect(result.any((r) => r.word == '失敗'), isTrue);
    });
  });

  group('mergeComposita', () {
    const bundledA = Composita(
      word: '食堂',
      reading: 'しょくどう',
      meaning: 'cafeteria',
      jlptLevel: 4,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );
    const bundledB = Composita(
      word: '食事',
      reading: 'しょくじ',
      meaning: 'meal',
      jlptLevel: 4,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );

    test('deduplicates by word, keeping bundled entry over user-added', () {
      const userAdded = Composita(
        word: '食堂',
        reading: 'しょくどう',
        meaning: 'user version',
        jlptLevel: null,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      const userNew = Composita(
        word: '食べる',
        reading: 'たべる',
        meaning: 'to eat',
        jlptLevel: null,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      final result = mergeComposita([bundledA, bundledB], [userAdded, userNew]);
      expect(result, hasLength(3)); // bundledA, bundledB, userNew (no dup)
      // The 食堂 entry should be the bundled one (meaning 'cafeteria').
      final shokudo = result.firstWhere((c) => c.word == '食堂');
      expect(shokudo.meaning, 'cafeteria');
    });

    test('returns bundled unchanged when userAdded is null', () {
      final result = mergeComposita([bundledA, bundledB], null);
      expect(result, [bundledA, bundledB]);
    });

    test('returns bundled unchanged when userAdded is empty', () {
      final result = mergeComposita([bundledA, bundledB], []);
      expect(result, [bundledA, bundledB]);
    });
  });

  group('eligibleComposita — kana-only filtering', () {
    test('kana-only words excluded even when explicitly selected', () {
      const kanaOnly = Composita(
        word: 'しかし',
        reading: 'しかし',
        meaning: 'however',
        jlptLevel: 4,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      const withKanji = Composita(
        word: '一つ',
        reading: 'ひとつ',
        meaning: 'one (thing)',
        jlptLevel: 5,
        inferredJlptLevel: null,
        frequencyRank: 1,
      );
      const scope = StudyScope(characters: {'一'});
      final result = eligibleComposita(
        [kanaOnly, withKanji],
        scope,
        {'しかし', '一つ'},
      );
      expect(result, [withKanji]);
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
