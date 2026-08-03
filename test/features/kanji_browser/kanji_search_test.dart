import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/kanji_info_repository.dart';
import 'package:kanjitomo/features/kanji_browser/kanji_search.dart';

void main() {
  group('toHiragana', () {
    test('converts katakana to hiragana', () {
      expect(toHiragana('スイ'), 'すい');
    });

    test('leaves hiragana and other characters untouched', () {
      expect(toHiragana('みず'), 'みず');
      expect(toHiragana('water'), 'water');
      expect(toHiragana('水'), '水');
    });

    test('handles mixed katakana/hiragana/kanji in one string', () {
      expect(toHiragana('水スイみず'), '水すいみず');
    });
  });

  group('matchesKanjiSearch', () {
    const water = KanjiInfo(
      on: ['スイ'],
      kun: ['みず', 'みず-'],
      meanings: ['water'],
      radicals: [],
    );
    const study = KanjiInfo(
      on: ['ガク'],
      kun: ['まな.ぶ'],
      meanings: ['study', 'learning', 'science'],
      radicals: ['子', '⺌', '冖'],
    );

    test('empty query matches everything', () {
      expect(
        matchesKanjiSearch(
          character: '水',
          info: water,
          strokeCount: 4,
          query: '',
        ),
        isTrue,
      );
    });

    test('matches the character itself', () {
      expect(
        matchesKanjiSearch(
          character: '水',
          info: water,
          strokeCount: 4,
          query: '水',
        ),
        isTrue,
      );
      expect(
        matchesKanjiSearch(
          character: '水',
          info: water,
          strokeCount: 4,
          query: '学',
        ),
        isFalse,
      );
    });

    test('matches on\'yomi typed in katakana or hiragana', () {
      expect(
        matchesKanjiSearch(
          character: '水',
          info: water,
          strokeCount: 4,
          query: 'スイ',
        ),
        isTrue,
      );
      expect(
        matchesKanjiSearch(
          character: '水',
          info: water,
          strokeCount: 4,
          query: 'すい',
        ),
        isTrue,
      );
    });

    test('matches kun\'yomi, ignoring the trailing "-" bound-form marker', () {
      expect(
        matchesKanjiSearch(
          character: '水',
          info: water,
          strokeCount: 4,
          query: 'みず',
        ),
        isTrue,
      );
    });

    test(
      'matches kun\'yomi ignoring the "." okurigana-boundary marker -- '
      '学 (まな.ぶ) matches both まな and まなぶ',
      () {
        expect(
          matchesKanjiSearch(
            character: '学',
            info: study,
            strokeCount: 8,
            query: 'まな',
          ),
          isTrue,
        );
        expect(
          matchesKanjiSearch(
            character: '学',
            info: study,
            strokeCount: 8,
            query: 'まなぶ',
          ),
          isTrue,
        );
      },
    );

    test('matches a meaning phrase, case-insensitively, as a substring', () {
      expect(
        matchesKanjiSearch(
          character: '学',
          info: study,
          strokeCount: 8,
          query: 'LEARN',
        ),
        isTrue,
      );
      expect(
        matchesKanjiSearch(
          character: '学',
          info: study,
          strokeCount: 8,
          query: 'learning',
        ),
        isTrue,
      );
    });

    test(
      'a bare integer query matches by exact stroke count instead of '
      'reading/meaning -- never partial/range matching',
      () {
        expect(
          matchesKanjiSearch(
            character: '水',
            info: water,
            strokeCount: 4,
            query: '4',
          ),
          isTrue,
        );
        expect(
          matchesKanjiSearch(
            character: '学',
            info: study,
            strokeCount: 8,
            query: '4',
          ),
          isFalse,
        );
        // Not 1 or 4 -- an integer query must never fall through to
        // matching '4' as a substring of some other stroke count like 14,
        // 24, etc. (there's no such case here, but exact-int comparison
        // guarantees it structurally.)
        expect(
          matchesKanjiSearch(
            character: '水',
            info: water,
            strokeCount: null,
            query: '4',
          ),
          isFalse,
        );
      },
    );

    test('no match when info is null (kana/REJECT) and query is text', () {
      expect(
        matchesKanjiSearch(
          character: 'あ',
          info: null,
          strokeCount: 1,
          query: 'anything',
        ),
        isFalse,
      );
    });
  });
}
