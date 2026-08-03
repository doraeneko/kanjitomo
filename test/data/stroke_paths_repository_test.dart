import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/stroke_paths_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real bundled asset', () async {
    final repo = StrokePathsRepository();
    await repo.load().timeout(const Duration(seconds: 10));
    final strokes = repo.lookup('愛');
    expect(strokes, isNotNull);
    expect(strokes!.strokeCount, 13);
  });
}
