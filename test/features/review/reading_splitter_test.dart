import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/kanji_info_repository.dart';
import 'package:kanjitomo/data/sentences_repository.dart';
import 'package:kanjitomo/features/review/reading_splitter.dart';

/// Minimal KanjiInfo factory for testing.
KanjiInfo _info({
  List<String> on = const [],
  List<String> kun = const [],
}) =>
    KanjiInfo(on: on, kun: kun, meanings: [], radicals: []);

final _testKanji = <String, KanjiInfo>{
  '東': _info(on: ['トウ'], kun: ['ひがし']),
  '京': _info(on: ['キョウ', 'ケイ', 'キン'], kun: ['みやこ']),
  '食': _info(on: ['ショク', 'ジキ'], kun: ['く.う', 'く.らう', 'た.べる', 'は.む']),
  '放': _info(on: ['ホウ'], kun: ['はな.す', 'はな.つ', 'はな.れる', 'ほう.る']),
  '題': _info(on: ['ダイ'], kun: []),
  '一': _info(on: ['イチ', 'イツ'], kun: ['ひと-', 'ひと.つ']),
  '番': _info(on: ['バン'], kun: ['つが.い']),
  '人': _info(on: ['ジン', 'ニン'], kun: ['ひと', '-り', '-と']),
  '生': _info(on: ['セイ', 'ショウ'], kun: ['い.きる', 'う.まれる', 'なま']),
  '日': _info(on: ['ニチ', 'ジツ'], kun: ['ひ', '-び', '-か']),
  '本': _info(on: ['ホン'], kun: ['もと']),
  '大': _info(on: ['ダイ', 'タイ'], kun: ['おお-', 'おお.きい', '-おお.いに']),
  '学': _info(on: ['ガク'], kun: ['まな.ぶ']),
  '先': _info(on: ['セン'], kun: ['さき', 'ま.ず']),
  '行': _info(on: ['コウ', 'ギョウ', 'アン'], kun: ['い.く', 'ゆ.く', 'おこな.う']),
  '太': _info(on: ['タイ', 'タ'], kun: ['ふと.い', 'ふと.る']),
  '腹': _info(on: ['フク'], kun: ['はら']),
  '丸': _info(on: ['ガン'], kun: ['まる', 'まる.める', 'まる.い']),
  '柱': _info(on: ['チュウ'], kun: ['はしら']),
  '取': _info(on: ['シュ'], kun: ['と.る', 'と.り', 'とり', '-ど.り']),
  '消': _info(on: ['ショウ'], kun: ['き.える', 'け.す']),
};

KanjiInfo? _lookup(String char) => _testKanji[char];

void main() {
  group('katakanaToHiragana', () {
    test('converts katakana to hiragana', () {
      expect(katakanaToHiragana('トウキョウ'), 'とうきょう');
      expect(katakanaToHiragana('ショク'), 'しょく');
    });

    test('leaves hiragana unchanged', () {
      expect(katakanaToHiragana('ひがし'), 'ひがし');
    });

    test('handles empty string', () {
      expect(katakanaToHiragana(''), '');
    });
  });

  group('splitReading', () {
    test('pure kanji word: 東京 → とうきょう', () {
      final result = splitReading('東京', 'とうきょう', _lookup);
      expect(result, ['とう', 'きょう']);
    });

    test('kanji + okurigana: 食べる → たべる', () {
      final result = splitReading('食べる', 'たべる', _lookup);
      expect(result, ['た', 'べ', 'る']);
    });

    test('mixed: 食べ放題 → たべほうだい', () {
      final result = splitReading('食べ放題', 'たべほうだい', _lookup);
      expect(result, ['た', 'べ', 'ほう', 'だい']);
    });

    test('single kanji: 人 → ひと', () {
      final result = splitReading('人', 'ひと', _lookup);
      expect(result, ['ひと']);
    });

    test('single kanji on-yomi: 人 → じん', () {
      final result = splitReading('人', 'じん', _lookup);
      expect(result, ['じん']);
    });

    test('一番 → いちばん', () {
      final result = splitReading('一番', 'いちばん', _lookup);
      expect(result, ['いち', 'ばん']);
    });

    test('日本 → にほん returns null (に is not a listed reading of 日)', () {
      // 日 has ニチ/ジツ/ひ but not に alone — the compound reading にほん
      // can't be split from dictionary readings, so the conservative
      // splitter bails out.
      final result = splitReading('日本', 'にほん', _lookup);
      expect(result, isNull);
    });

    test('大学 → だいがく', () {
      final result = splitReading('大学', 'だいがく', _lookup);
      expect(result, ['だい', 'がく']);
    });

    test('先生 → せんせい', () {
      final result = splitReading('先生', 'せんせい', _lookup);
      expect(result, ['せん', 'せい']);
    });

    test('取り消す → とりけす', () {
      final result = splitReading('取り消す', 'とりけす', _lookup);
      expect(result, ['と', 'り', 'け', 'す']);
    });

    test('returns null when reading is too short', () {
      final result = splitReading('東京', 'あ', _lookup);
      expect(result, isNull);
    });

    test('returns null for known kanji with non-standard compound reading', () {
      // 丸柱 reads as えんちゅう but 丸 has no えん reading (only がん/まる).
      // The conservative splitter should return null rather than guess.
      final result = splitReading('丸柱', 'えんちゅう', _lookup);
      expect(result, isNull);
    });

    test('returns null for rendaku where known reading does not match', () {
      // 太っ腹: 腹 reads as ぱら (rendaku of はら), which doesn't match
      // any known reading. Should return null.
      final result = splitReading('太っ腹', 'ふとっぱら', _lookup);
      expect(result, isNull);
    });

    test('handles unknown kanji via fallback', () {
      // 鬱 is not in our test dictionary — fallback is allowed.
      final result = splitReading('鬱', 'うつ', _lookup);
      expect(result, ['うつ']);
    });

    test('pure kana word passes through', () {
      final result = splitReading('する', 'する', _lookup);
      expect(result, ['す', 'る']);
    });
  });

  group('splitReading with rendaku/voicing', () {
    test('一番 handles rendaku ばん from バン', () {
      // バン → ばん matches directly (not rendaku, the reading IS ばん).
      final result = splitReading('一番', 'いちばん', _lookup);
      expect(result, ['いち', 'ばん']);
    });
  });

  group('splitTargetToken', () {
    test('splits with unseen kanji getting isTarget=false', () {
      final target = SentenceToken(
        surface: '東京',
        reading: 'とうきょう',
        isTarget: true,
      );
      // 東 is seen, 京 is unseen
      final result = splitTargetToken(target, _lookup, {'東'});
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].surface, '東');
      expect(result[0].reading, 'とう');
      expect(result[0].isTarget, true); // seen → target (reading hidden)
      expect(result[1].surface, '京');
      expect(result[1].reading, 'きょう');
      expect(result[1].isTarget, false); // unseen → not target (reading shown as hint)
    });

    test('all kanji seen: all sub-tokens are isTarget=true', () {
      final target = SentenceToken(
        surface: '東京',
        reading: 'とうきょう',
        isTarget: true,
      );
      final result = splitTargetToken(target, _lookup, {'東', '京'});
      expect(result, isNotNull);
      expect(result!.every((t) => t.isTarget), true);
    });

    test('returns null when splitting fails', () {
      final target = SentenceToken(
        surface: '東京',
        reading: 'あ', // too short for 2 chars
        isTarget: true,
      );
      final result = splitTargetToken(target, _lookup, {});
      expect(result, isNull);
    });

    test('returns null for non-standard compound readings', () {
      final target = SentenceToken(
        surface: '太っ腹',
        reading: 'ふとっぱら',
        isTarget: true,
      );
      // Rendaku — splitter can't match, returns null (safe fallback).
      final result = splitTargetToken(target, _lookup, {});
      expect(result, isNull);
    });

    test('kana characters are always isTarget=true', () {
      final target = SentenceToken(
        surface: '食べる',
        reading: 'たべる',
        isTarget: true,
      );
      // 食 is unseen
      final result = splitTargetToken(target, _lookup, {});
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0].surface, '食');
      expect(result[0].isTarget, false); // unseen kanji → hint
      expect(result[1].surface, 'べ');
      expect(result[1].isTarget, true); // kana → always target
      expect(result[2].surface, 'る');
      expect(result[2].isTarget, true); // kana → always target
    });
  });
}
