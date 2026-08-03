import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/stories_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real bundled asset', () async {
    final repo = StoriesRepository();
    await repo.load().timeout(const Duration(seconds: 10));

    expect(repo.all['本']!.keyword, 'Buch');
    expect(repo.all['本']!.story, contains('TREEs'));
    // Coverage isn't total -- karten.json doesn't cover every Joyo kanji
    // (see build_stories.py's own coverage report).
    expect(repo.all.length, greaterThan(2000));
    expect(repo.all.length, lessThan(2140));
  });
}
