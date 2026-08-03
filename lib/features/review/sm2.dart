/// Pure SM-2 scheduling logic -- zero Flutter/DB imports, so it's directly
/// unit-testable without a running app or database. See
/// review_repository.dart for how this composes with persisted state.
library;

/// One SM-2 review outcome: `q` in [0, 5] where q<3 is a failed recall.
class Sm2State {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;

  const Sm2State({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
  });
}

const double _minEaseFactor = 1.3;
const double _defaultEaseFactor = 2.5;

/// The SM-2 algorithm (Wozniak). [current] is null for a card with no prior
/// review (fresh/new card) -- treated as ease=2.5, interval=0, repetitions=0.
Sm2State computeNextReview(Sm2State? current, int quality) {
  assert(quality >= 0 && quality <= 5);
  final easeFactor = current?.easeFactor ?? _defaultEaseFactor;
  final repetitions = current?.repetitions ?? 0;
  final priorInterval = current?.intervalDays ?? 0;

  final int nextRepetitions;
  final int nextInterval;
  if (quality < 3) {
    nextRepetitions = 0;
    nextInterval = 1;
  } else {
    nextRepetitions = repetitions + 1;
    nextInterval = switch (repetitions) {
      0 => 1,
      1 => 6,
      _ => (priorInterval * easeFactor).round(),
    };
  }

  final delta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
  final nextEaseFactor = (easeFactor + delta) < _minEaseFactor
      ? _minEaseFactor
      : easeFactor + delta;

  return Sm2State(
    easeFactor: nextEaseFactor,
    intervalDays: nextInterval,
    repetitions: nextRepetitions,
  );
}

/// One candidate the recognizer returned, decoupled from KanjiRecognizer's
/// own Prediction type so this file stays free of Flutter/plugin imports.
class RecognitionCandidate {
  final String label;
  const RecognitionCandidate(this.label);
}

/// Grades a drawInSentence/drawFromMeaning card: the user drew [target],
/// the recognizer's top candidates are [topCandidates], and the user
/// tapped [userPick] as the one they intended. [topCandidates] is usually
/// 3 long, but can be shorter -- DrawAndPickWidget collapses to a single
/// candidate when the recognizer is already highly confident, since
/// there's nothing left to disambiguate.
///
/// - target absent from topCandidates: q=0, the drawing itself wasn't
///   recognized as a plausible candidate.
/// - target present but user tapped a different candidate: q=2, recalled
///   *something* familiar but misidentified it -- weaker than a blackout,
///   but still a failed recall (q<3).
/// - target present and correctly picked: q=5/4/3 by rank (1st/2nd/3rd+) --
///   rank 3+ is exactly SM-2's canonical "correct with serious difficulty"
///   boundary.
int gradeDrawAndPick({
  required String target,
  required List<RecognitionCandidate> topCandidates,
  required String userPick,
}) {
  assert(topCandidates.isNotEmpty);
  final rank = topCandidates.indexWhere((c) => c.label == target);
  if (rank == -1) return 0;
  if (userPick != target) return 2;
  return switch (rank) { 0 => 5, 1 => 4, _ => 3 };
}
