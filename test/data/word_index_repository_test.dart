import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/word_index_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real bundled asset and resolves exact-word lookups', () async {
    final repo = WordIndexRepository();
    await repo.load().timeout(const Duration(seconds: 10));

    final nihon = repo.lookup('日本');
    expect(nihon, isNotEmpty);
    expect(nihon.first.kana, contains('にほん'));
    expect(nihon.first.meaning, contains('Japan'));

    // Kana-only word, only reachable by its kana form (see
    // build_word_index.py's docstring on why build_composita.py's
    // kanji-only indexing would miss this one).
    final arigatou = repo.lookup('ありがとう');
    expect(arigatou, isNotEmpty);
    expect(arigatou.first.meaning, contains('thank'));

    expect(repo.lookup('normalcy'), isEmpty);
  });
}
