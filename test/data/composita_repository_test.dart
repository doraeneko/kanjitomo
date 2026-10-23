import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/data/composita_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the real bundled asset', () async {
    final repo = CompositaRepository();
    await repo.load().timeout(const Duration(seconds: 10));

    final ichi = repo.lookup('一');
    expect(ichi, isNotEmpty);
    // build_composita.py caps per EFFECTIVE JLPT level (1-5, or untagged),
    // not one flat total -- up to 20 per bucket across 6 possible buckets,
    // so a common kanji like 一 can legitimately have far more than 20
    // entries now (confirmed directly: 120, i.e. the full 20x6).
    expect(ichi.length, lessThanOrEqualTo(20 * 6));
    // Ranked JLPT-tagged-first, then inferred-level-first, then by
    // zipfFreq descending within each tier.
    for (var i = 1; i < ichi.length; i++) {
      final prevTagged = ichi[i - 1].jlptLevel == null;
      final curTagged = ichi[i].jlptLevel == null;
      final prevInferred = ichi[i - 1].inferredJlptLevel == null;
      final curInferred = ichi[i].inferredJlptLevel == null;
      final samePriorTiers =
          prevTagged == curTagged && prevInferred == curInferred;
      // Within the same tier, zipfFreq should be non-increasing.
      expect(
        samePriorTiers
            ? ichi[i - 1].zipfFreq >= ichi[i].zipfFreq
            : true,
        isTrue,
      );
    }

    // A word with no real tag but whose only kanji (丁) is itself
    // JLPT-tagged should get an inferred level instead -- confirmed
    // directly against the bundled asset.
    final chou = repo.lookup('丁').firstWhere((c) => c.word == '丁');
    expect(chou.jlptLevel, isNull);
    expect(chou.inferredJlptLevel, isNotNull);
    expect(chou.isLevelInferred, isTrue);
    expect(chou.effectiveJlptLevel, chou.inferredJlptLevel);

    expect(repo.lookup('REJECT'), isEmpty);
  });
}
