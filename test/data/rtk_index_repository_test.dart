import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/rtk_index_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real bundled asset', () async {
    final repo = RtkIndexRepository();
    await repo.load().timeout(const Duration(seconds: 10));

    expect(repo.indexOf('一'), 1);
    expect(repo.indexOf('二'), 2);
    // Known glyph-variant gap (see build_rtk_index.py) -- absent, not 0.
    expect(repo.indexOf('剝'), isNull);

    final upTo10 = repo.charsUpTo(10);
    expect(upTo10, contains('一'));
    expect(upTo10.every((c) => repo.indexOf(c)! <= 10), isTrue);
  });
}
