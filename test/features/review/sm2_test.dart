import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/features/review/sm2.dart';

void main() {
  group('computeNextReview', () {
    test('fresh card, q=5 (Easy): interval=1, repetitions=1', () {
      final result = computeNextReview(null, 5);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, greaterThan(2.5));
    });

    test('fresh card, q=0 (blackout): interval resets to 1, repetitions=0', () {
      final result = computeNextReview(null, 0);
      expect(result.repetitions, 0);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, lessThan(2.5));
    });

    test('second consecutive pass (repetitions 1->2): interval jumps to 6', () {
      final first = computeNextReview(null, 4);
      expect(first.repetitions, 1);
      expect(first.intervalDays, 1);

      final second = computeNextReview(first, 4);
      expect(second.repetitions, 2);
      expect(second.intervalDays, 6);
    });

    test('third+ consecutive pass: interval scales by ease factor', () {
      var state = computeNextReview(null, 4);
      state = computeNextReview(state, 4); // repetitions=2, interval=6
      final third = computeNextReview(state, 4);
      expect(third.repetitions, 3);
      expect(third.intervalDays, (6 * state.easeFactor).round());
    });

    test('q=2 (fail after establishment): repetitions resets, interval=1', () {
      var state = computeNextReview(null, 4);
      state = computeNextReview(state, 4);
      state = computeNextReview(state, 4); // well-established card
      final failed = computeNextReview(state, 2);
      expect(failed.repetitions, 0);
      expect(failed.intervalDays, 1);
    });

    test('q=3 (barely passing): still counts as a pass, interval grows', () {
      final result = computeNextReview(null, 3);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
    });

    test('ease factor never drops below 1.3 floor', () {
      var state = computeNextReview(null, 0);
      for (var i = 0; i < 20; i++) {
        state = computeNextReview(state, 0);
      }
      expect(state.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('higher quality increases ease factor more than lower quality', () {
      final easy = computeNextReview(null, 5);
      final good = computeNextReview(null, 4);
      expect(easy.easeFactor, greaterThan(good.easeFactor));
    });
  });

  group('gradeDrawAndPick', () {
    const top3 = [
      RecognitionCandidate('一'),
      RecognitionCandidate('二'),
      RecognitionCandidate('三'),
    ];

    test('target absent from top-3: q=0', () {
      final q = gradeDrawAndPick(
        target: '四',
        topCandidates: top3,
        userPick: '一',
      );
      expect(q, 0);
    });

    test('target present, user picks a different candidate: q=2', () {
      final q = gradeDrawAndPick(
        target: '二',
        topCandidates: top3,
        userPick: '一',
      );
      expect(q, 2);
    });

    test('target at rank 1 (index 0), correctly picked: q=5', () {
      final q = gradeDrawAndPick(
        target: '一',
        topCandidates: top3,
        userPick: '一',
      );
      expect(q, 5);
    });

    test('target at rank 2 (index 1), correctly picked: q=4', () {
      final q = gradeDrawAndPick(
        target: '二',
        topCandidates: top3,
        userPick: '二',
      );
      expect(q, 4);
    });

    test('target at rank 3 (index 2), correctly picked: q=3', () {
      final q = gradeDrawAndPick(
        target: '三',
        topCandidates: top3,
        userPick: '三',
      );
      expect(q, 3);
    });

    // Regression: DrawAndPickWidget collapses to a single candidate when
    // the recognizer is already confident (see draw_and_pick.dart's
    // confidentThreshold) -- gradeDrawAndPick used to hard-assert exactly
    // 3 candidates and crash whenever that collapse happened.
    test('a single confident candidate (correctly picked): q=5', () {
      final q = gradeDrawAndPick(
        target: '一',
        topCandidates: const [RecognitionCandidate('一')],
        userPick: '一',
      );
      expect(q, 5);
    });

    test('a single confident candidate that is wrong: q=0', () {
      final q = gradeDrawAndPick(
        target: '二',
        topCandidates: const [RecognitionCandidate('一')],
        userPick: '一',
      );
      expect(q, 0);
    });
  });
}
