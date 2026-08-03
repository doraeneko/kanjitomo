import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/sentences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real bundled asset', () async {
    final repo = SentencesRepository();
    await repo.load().timeout(const Duration(seconds: 10));

    final entries = repo.lookup('一番');
    expect(entries, isNotEmpty);
    expect(entries.length, lessThanOrEqualTo(5));

    final first = entries.first;
    expect(first.sentence, contains('一番'));
    expect(first.jlptLevel, inInclusiveRange(1, 5));
    expect(first.source, 'tatoeba');

    final targetTokens = first.tokens.where((t) => t.isTarget);
    expect(targetTokens, isNotEmpty);
    expect(targetTokens.first.surface, '一番');
    expect(targetTokens.first.reading, 'いちばん');

    expect(repo.lookup('絶対にありえない単語'), isEmpty);
  });

  test('ExampleSentence.fromJson parses translation when present, null otherwise', () {
    final withTranslation = ExampleSentence.fromJson({
      'sentence': '猫が好きです。',
      'tokens': <dynamic>[],
      'jlptLevel': 5,
      'source': 'tatoeba',
      'translation': 'I like cats.',
    });
    expect(withTranslation.translation, 'I like cats.');

    final explicitNull = ExampleSentence.fromJson({
      'sentence': '猫が好きです。',
      'tokens': <dynamic>[],
      'jlptLevel': 5,
      'source': 'tatoeba',
      'translation': null,
    });
    expect(explicitNull.translation, isNull);

    final keyAbsent = ExampleSentence.fromJson({
      'sentence': '猫が好きです。',
      'tokens': <dynamic>[],
      'jlptLevel': 5,
      'source': 'llm',
    });
    expect(keyAbsent.translation, isNull);
  });

  test('bundled asset has high (but not total) translation coverage', () async {
    final repo = SentencesRepository();
    await repo.load().timeout(const Duration(seconds: 10));

    var total = 0;
    var withTranslation = 0;
    for (final word in ['一番', '準備', '完了', '一向']) {
      for (final e in repo.lookup(word)) {
        total++;
        if (e.translation != null) withTranslation++;
      }
    }
    expect(total, greaterThan(0));
    // ~96% coverage confirmed directly against the build script's own
    // report -- not asserting 100%, since not every mined sentence has a
    // linked English translation.
    expect(withTranslation / total, greaterThan(0.5));
  });
}
