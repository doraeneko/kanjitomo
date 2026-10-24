import 'package:flutter_test/flutter_test.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/db/tables.dart';
import 'package:kanjitomo/features/review/review_repository.dart';

ReviewCard _card(String character, CardType cardType) {
  return ReviewCard(
    character: character,
    cardType: cardType,
    compositaWord: '',
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    dueDate: DateTime(2026, 1, 1),
    lapses: 0,
  );
}

List<ReviewCard> _cards(String chars, CardType type) =>
    [for (final c in chars.split('')) _card(c, type)];

void main() {
  group('planSession', () {
    final reviews = _cards('一二三四五', CardType.kanjiRecognition);
    final fresh = _cards('六七八九十', CardType.drawFromMeaning);

    test('new cards are capped per session', () {
      final plan = planSession(
        reviews: reviews,
        newCards: fresh,
        limits: const SessionLimits(maxReviewsPerDay: 200, newCardsPerSession: 2),
      );
      expect(plan.reviews, hasLength(5));
      expect(plan.newCards, hasLength(2));
      expect(plan.total, 7);
      expect(plan.remainingBeyondCap, 3);
    });

    test('the daily budget counts reviews done today and covers new cards too', () {
      final plan = planSession(
        reviews: reviews,
        newCards: fresh,
        limits: const SessionLimits(
          maxReviewsPerDay: 8, newCardsPerSession: 30, reviewedToday: 2),
      );
      expect(plan.reviews, hasLength(5));
      expect(plan.newCards, hasLength(1)); // 8 - 2 - 5
      expect(plan.total, 6);
    });

    test('learn-more extras come on top of the limits', () {
      final plan = planSession(
        reviews: reviews,
        newCards: fresh,
        limits: const SessionLimits(
          maxReviewsPerDay: 5, newCardsPerSession: 30, learnMoreRemaining: 3),
      );
      expect(plan.reviews, hasLength(5));
      expect(plan.newCards, isEmpty);
      expect(plan.extra.map((c) => c.character), ['六', '七', '八']);
      expect(plan.total, 8);
    });

    test('zero limits mean unlimited', () {
      final plan = planSession(
        reviews: reviews,
        newCards: fresh,
        limits: const SessionLimits(maxReviewsPerDay: 0, newCardsPerSession: 0),
      );
      expect(plan.total, 10);
      expect(plan.remainingBeyondCap, 0);
    });
  });

  test('SessionInputs.plan filters by card kind before applying limits', () {
    final inputs = SessionInputs(
      reviews: _cards('一二', CardType.kanjiRecognition),
      newCards: [
        ..._cards('三四五', CardType.drawFromMeaning),
        ..._cards('六七', CardType.kanjiRecognition),
      ],
      limits: const SessionLimits(newCardsPerSession: 2),
    );
    expect(inputs.plan().total, 4); // 2 reviews + 2 new (cap)
    final kanjiRecognitionOnly =
        inputs.plan(cardTypes: {CardType.kanjiRecognition});
    expect(kanjiRecognitionOnly.newCards.map((c) => c.character), ['六', '七']);
    expect(inputs.plan(cardTypes: {CardType.readingCloze}).total, 0);
  });
}
