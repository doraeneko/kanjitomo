import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/features/learning/anki_import_screen.dart';

void main() {
  group('pickKanjiFieldIndex', () {
    test('prefers the vocabulary field over the example sentence', () {
      final notes = [
        ['学校', 'がっこう', 'school', '<b>学校</b>に行きます。'],
        ['先生', 'せんせい', 'teacher', '先生は日本人です。'],
        ['電車', 'でんしゃ', 'train', '電車で会社に行く。'],
      ];
      expect(pickKanjiFieldIndex(notes), 0);
    });

    test('ignores a field that only rarely contains kanji', () {
      final notes = [
        ['meaning', '日', ''],
        ['meaning', '月', '日本語の文'],
        ['meaning', '火', ''],
        ['meaning', '水', ''],
        ['meaning', '木', ''],
      ];
      expect(pickKanjiFieldIndex(notes), 1);
    });

    test('works without field names and with no notes', () {
      expect(pickKanjiFieldIndex(const []), 0);
      expect(pickKanjiFieldIndex([['abc', 'def']]), 0);
    });
  });

  test('stripAnkiHtml removes tags and entities', () {
    expect(stripAnkiHtml('<div>漢字&nbsp;</div><br/>'), '漢字');
  });
}
