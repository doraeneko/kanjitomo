import '../../core/db/tables.dart';

/// Which of the four learning axes (see plan.md's A/B/C/D framing) a review
/// session introduces and quizzes -- chosen fresh each time in
/// ReviewStartScreen, not persisted as part of StudyScope: a scope defines
/// WHICH kanji/composita are in play, this defines WHICH skill is being
/// quizzed on top of that scope.
enum ReviewFocus {
  core, // draw-from-meaning + kanji recognition (per-kanji skills)
  composita, // composita/sentence reading + drawing (compound-word skills)
  both,
}

/// The concrete CardTypes [focus] restricts a session to, or null for
/// "both" (every CardType, no restriction) -- null rather than the full
/// CardType.values set so ReviewFocus.both callers pass straight through
/// unfiltered, identical to this app's pre-ReviewFocus behavior.
Set<CardType>? cardTypesForFocus(ReviewFocus focus) => switch (focus) {
  ReviewFocus.core => {CardType.drawFromMeaning, CardType.kanjiRecognition},
  ReviewFocus.composita => {CardType.readingCloze, CardType.drawInSentence},
  ReviewFocus.both => null,
};
