import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/composita_repository.dart';
import 'package:kanjitomo/data/kanji_info_repository.dart';
import 'package:kanjitomo/features/quiz/quiz_distractors.dart';

Composita _composita(String word, String reading, {int? jlptLevel}) =>
    Composita(
      word: word,
      reading: reading,
      meaning: 'test',
      jlptLevel: jlptLevel,
      inferredJlptLevel: null,
      frequencyRank: 1,
    );

void main() {
  group('editDistance', () {
    test('identical strings have distance 0', () {
      expect(editDistance('abc', 'abc'), 0);
    });

    test('empty vs non-empty', () {
      expect(editDistance('', 'abc'), 3);
      expect(editDistance('abc', ''), 3);
    });

    test('single substitution', () {
      expect(editDistance('abc', 'axc'), 1);
    });

    test('insertion and deletion', () {
      expect(editDistance('abc', 'abcd'), 1);
      expect(editDistance('abcd', 'abc'), 1);
    });

    test('completely different', () {
      expect(editDistance('abc', 'xyz'), 3);
    });

    test('works with Japanese hiragana', () {
      expect(editDistance('たべる', 'たべる'), 0);
      expect(editDistance('たべる', 'たべた'), 1);
      expect(editDistance('きく', 'きく'), 0);
      expect(editDistance('きく', 'きっく'), 1);
    });
  });

  group('confusableReadings', () {
    test('generates voicing variants', () {
      final results = confusableReadings('かく');
      expect(results, contains('がく')); // か→が
      expect(results, contains('かぐ')); // く→ぐ
    });

    test('generates long vowel variants for お-column', () {
      final results = confusableReadings('こ');
      expect(results, contains('こう'));
    });

    test('removes long vowel う', () {
      final results = confusableReadings('こう');
      expect(results, contains('こ'));
    });

    test('generates long vowel variants for い-column', () {
      final results = confusableReadings('き');
      expect(results, contains('きい'));
    });

    test('removes long vowel い', () {
      final results = confusableReadings('きい');
      expect(results, contains('き'));
    });

    test('generates gemination variants', () {
      final results = confusableReadings('いた');
      expect(results, contains('いった'));
    });

    test('removes gemination っ', () {
      final results = confusableReadings('いった');
      expect(results, contains('いた'));
    });

    test('generates ha-row variants', () {
      final results = confusableReadings('はし');
      expect(results, contains('ばし'));
      expect(results, contains('ぱし'));
    });

    test('does not generate same-row vowel swaps', () {
      // Same-row swaps (し→す, た→と) are too obviously wrong.
      final results = confusableReadings('し');
      expect(results, isNot(contains('さ')));
      expect(results, isNot(contains('す')));
      expect(results, isNot(contains('せ')));
      expect(results, isNot(contains('そ')));
    });

    test('generates ん insertion', () {
      final results = confusableReadings('しか');
      expect(results, contains('しんか'));
    });

    test('removes ん', () {
      final results = confusableReadings('しんか');
      expect(results, contains('しか'));
    });

    test('does not include the original reading', () {
      final results = confusableReadings('たべ');
      expect(results, isNot(contains('たべ')));
    });

    test('generates double-op variants for short inputs', () {
      // 'かく' has limited single-op variants (がく, かぐ, etc.);
      // double-ops should be generated too (e.g. がぐ).
      final results = confusableReadings('かく');
      expect(results.length, greaterThanOrEqualTo(3));
      // Should include double-op variant がぐ (both voiced).
      expect(results, contains('がぐ'));
    });

    test('all variants are within ±1 char of correct length', () {
      final correct = 'しゅっぱつ'; // 5 chars
      final results = confusableReadings(correct);
      for (final r in results) {
        expect((r.length - correct.length).abs(), lessThanOrEqualTo(1),
            reason: '"$r" (${r.length}) is too different from '
                '"$correct" (${correct.length})');
      }
    });
  });

  group('readingDistractors', () {
    test('returns up to 3 distractors', () {
      final pool = <Composita>[];
      final result = readingDistractors('たべる', pool);
      expect(result.length, 3);
      expect(result, isNot(contains('たべる')));
    });

    test('all distractors are plausible confusions', () {
      final pool = <Composita>[];
      final result = readingDistractors('きんこう', pool);
      for (final d in result) {
        // Each distractor should be within ±1 of the correct length.
        expect((d.length - 'きんこう'.length).abs(), lessThanOrEqualTo(1),
            reason: '"$d" is too different in length from きんこう');
      }
    });

    test('returns fewer than 3 for very short readings with few ops', () {
      final pool = <Composita>[];
      final result = readingDistractors('あ', pool);
      // 'あ' has very limited transformations.
      expect(result, isNot(contains('あ')));
    });
  });

  group('charReadingDistractors', () {
    KanjiInfo? _lookup(String ch) {
      if (ch == '均') {
        return const KanjiInfo(
          on: ['キン'], kun: [], meanings: ['equal'],
          radicals: ['土'],
        );
      }
      if (ch == '百') {
        return const KanjiInfo(
          on: ['ヒャク'], kun: [], meanings: ['hundred'],
          radicals: ['白'],
        );
      }
      return null;
    }

    test('returns full-word readings when wordSplits provided', () {
      final pool = <Composita>[];
      final result = charReadingDistractors(
        'きん', '均', _lookup, pool,
        wordSplits: ['ひゃく', 'きん'],
        targetIndex: 1,
      );
      // All distractors should be full-word readings starting with ひゃく.
      for (final d in result) {
        expect(d, startsWith('ひゃく'),
            reason: 'distractor "$d" should keep the untested part ひゃく');
        expect(d, isNot(equals('ひゃくきん')),
            reason: 'distractor should differ from correct');
      }
    });

    test('varies only the tested character portion', () {
      final pool = <Composita>[];
      final result = charReadingDistractors(
        'きん', '均', _lookup, pool,
        wordSplits: ['ひゃく', 'きん'],
        targetIndex: 1,
      );
      // Should include ひゃくぎん (voicing き→ぎ).
      expect(result, contains('ひゃくぎん'));
    });

    test('all distractors are plausible confusions of the tested reading', () {
      final pool = <Composita>[];
      final result = charReadingDistractors(
        'きん', '均', _lookup, pool,
        wordSplits: ['ひゃく', 'きん'],
        targetIndex: 1,
      );
      // Every distractor should differ from ひゃくきん only in the きん part.
      for (final d in result) {
        expect(d, startsWith('ひゃく'),
            reason: 'only the tested portion should change');
        final variedPart = d.substring('ひゃく'.length);
        expect(variedPart, isNot(equals('きん')));
        // The varied part should be within ±1 of きん length (2).
        expect((variedPart.length - 'きん'.length).abs(), lessThanOrEqualTo(1),
            reason: 'varied part "$variedPart" should be similar length to きん');
      }
    });

    test('returns per-char readings when no wordSplits', () {
      final pool = <Composita>[];
      final result = charReadingDistractors(
        'きん', '均', _lookup, pool,
      );
      for (final d in result) {
        expect(d, isNot(contains('ひゃく')));
      }
    });
  });

  group('kanjiWordDistractors', () {
    test('returns up to 3 distractors', () {
      final pool = [
        _composita('食事', 'しょくじ'),
        _composita('食物', 'しょくもつ'),
        _composita('食堂', 'しょくどう'),
        _composita('事故', 'じこ'),
        _composita('人事', 'じんじ'),
      ];
      final result = kanjiWordDistractors('食事', pool);
      expect(result.length, 3);
      expect(result, isNot(contains('食事')));
    });

    test('prefers words sharing a kanji', () {
      final pool = [
        _composita('食事', 'しょくじ'),
        _composita('食物', 'しょくもつ'),
        _composita('事故', 'じこ'),
        _composita('人食', 'ひとくい'),
        _composita('山川', 'やまかわ'),
        _composita('大小', 'だいしょう'),
      ];
      final result = kanjiWordDistractors('食事', pool);
      expect(result.length, 3);
      final sharingKanji = result.where((w) =>
          w.contains('食') || w.contains('事')).length;
      expect(sharingKanji, greaterThanOrEqualTo(2));
    });

    test('returns fewer than 3 when pool is small', () {
      final pool = [
        _composita('食事', 'しょくじ'),
        _composita('食物', 'しょくもつ'),
      ];
      final result = kanjiWordDistractors('食事', pool);
      expect(result.length, 1);
      expect(result, ['食物']);
    });

    test('uses radical similarity when kanjiLookup provided', () {
      KanjiInfo? lookup(String ch) {
        switch (ch) {
          case '木': return const KanjiInfo(
            on: ['モク'], kun: ['き'], meanings: ['tree'],
            radicals: ['木'],
          );
          case '本': return const KanjiInfo(
            on: ['ホン'], kun: ['もと'], meanings: ['book'],
            radicals: ['木', '一'],
          );
          case '林': return const KanjiInfo(
            on: ['リン'], kun: ['はやし'], meanings: ['grove'],
            radicals: ['木'],
          );
          case '森': return const KanjiInfo(
            on: ['シン'], kun: ['もり'], meanings: ['forest'],
            radicals: ['木'],
          );
          case '金': return const KanjiInfo(
            on: ['キン'], kun: ['かね'], meanings: ['gold'],
            radicals: ['金'],
          );
          case '銀': return const KanjiInfo(
            on: ['ギン'], kun: [], meanings: ['silver'],
            radicals: ['金'],
          );
          case '山': return const KanjiInfo(
            on: ['サン'], kun: ['やま'], meanings: ['mountain'],
            radicals: ['山'],
          );
          default: return null;
        }
      }

      final pool = [
        _composita('木金', 'もくきん'),
        _composita('本金', 'ほんきん'),
        _composita('林金', 'りんきん'),
        _composita('山銀', 'さんぎん'),
        _composita('森金', 'しんきん'),
      ];

      final result = kanjiWordDistractors(
        '木金', pool,
        kanjiLookup: lookup,
      );
      expect(result.length, 3);
      final withSharedRadical = result.where(
        (w) => w.contains('本') || w.contains('林') || w.contains('森'),
      ).length;
      expect(withSharedRadical, greaterThanOrEqualTo(2));
    });

    test('works without kanjiLookup (backward compatible)', () {
      final pool = [
        _composita('食事', 'しょくじ'),
        _composita('食物', 'しょくもつ'),
        _composita('事故', 'じこ'),
        _composita('人事', 'じんじ'),
      ];
      final result = kanjiWordDistractors('食事', pool);
      expect(result.length, 3);
    });
  });
}
