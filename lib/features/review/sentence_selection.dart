import '../../data/composita_repository.dart';
import '../../data/sentences_repository.dart';
import 'study_scope.dart';

/// Whether composita/sentence testing (C+D) is enabled at all for [scope].
/// JLPT mode requires the user to have explicitly picked a
/// [StudyScope.compositaCeiling] -- null there means "not opted in yet",
/// not "unrestricted" (a flood of every composita across every JLPT level
/// the moment a kanji level is picked would be a poor silent default).
/// RTK/custom mode aren't gated here: RTK isn't surfaced in any new/
/// reworked screen at all (composita/sentence testing included), and
/// custom mode's composita scope is chosen per-kanji (see
/// CustomComposita), not via a level ceiling.
bool compositaEnabled(StudyScope scope) =>
    scope.mode != StudyScopeMode.jlpt || scope.compositaCeiling != null;

/// The hardest JLPT level (numerically lowest -- N1=1 is hardest, N5=5 is
/// easiest) [scope] should ever expose composita/sentence content at, or
/// null when there's no such ceiling (RTK/custom mode -- unrestricted; or
/// JLPT mode with no ceiling chosen yet, in which case callers should
/// check [compositaEnabled] first rather than treat this null as
/// "unrestricted" too).
///
/// A composita word's own jlptLevel is a WORD-level classification,
/// independent of a character's own (kanji-level) JLPT tag that
/// [StudyScope] actually filters characters by -- e.g. 並 is an N2 kanji,
/// but its composita word 月並 is tagged N1, so a ceiling deliberately
/// independent of which kanji levels are selected (see
/// [StudyScope.compositaCeiling]) is what decides whether that word is
/// welcome, not [StudyScope.jlptLevels].
int? jlptCeilingFor(StudyScope scope) {
  if (scope.mode != StudyScopeMode.jlpt) return null;
  return scope.compositaCeiling;
}

/// Whether [composita]'s own effective JLPT level (real tag, else the
/// kanji-inferred estimate) is at or easier than [ceiling] -- true
/// unconditionally when there's no ceiling to respect. A word with no
/// classification at all (neither real nor inferred) can't be confirmed
/// safe, so it's excluded whenever a ceiling applies, same conservative
/// choice as build_composita.py's own inference (never guess through a
/// gap).
bool compositaWithinCeiling(Composita composita, int? ceiling) {
  if (ceiling == null) return true;
  final level = composita.effectiveJlptLevel;
  return level != null && level >= ceiling;
}

/// Which of [all] (one character's composita) are actually eligible for
/// C+D testing under [scope]: in custom mode, exactly [customSelected]
/// (the words explicitly attached via custom_edit_screen.dart) -- no
/// ceiling-based fallback, since custom mode's whole point is a
/// hand-picked list, not "everything up to some level". In jlpt mode,
/// every composita at or under the scope's own compositaCeiling (see
/// [compositaWithinCeiling]).
List<Composita> eligibleComposita(
  List<Composita> all,
  StudyScope scope,
  Set<String> customSelected,
) {
  if (scope.mode == StudyScopeMode.custom) {
    return all.where((c) => customSelected.contains(c.word)).toList();
  }
  final ceiling = jlptCeilingFor(scope);
  return all.where((c) => compositaWithinCeiling(c, ceiling)).toList();
}

/// Picks which of [eligible] composita to test next, preferring one whose
/// reading isn't already in [testedWords] -- so a character with several
/// testable readings actually gets exercised on all of them over repeated
/// reviews, instead of always landing on the same (first, usually
/// frequency-ranked) word forever. Falls back to the first entry once
/// everything in [eligible] has already been tested at least once (still
/// worth reviewing, just no longer "new"). Null when [eligible] is empty.
Composita? pickUntested(List<Composita> eligible, Set<String> testedWords) {
  for (final c in eligible) {
    if (!testedWords.contains(c.word)) return c;
  }
  return eligible.isEmpty ? null : eligible.first;
}

/// A single-token stand-in "sentence" for [composita], used when it has no
/// real example-sentence coverage -- lets composita-only testing (C: draw/
/// read the word in isolation, no mined sentence context) run through the
/// same [FuriganaSentence]-based card builders as a real sentence (D),
/// since that widget already accepts a plain token list and only cares
/// which one is flagged as the target.
ExampleSentence syntheticSentenceFor(Composita composita) {
  return ExampleSentence(
    sentence: composita.word,
    tokens: [
      SentenceToken(
        surface: composita.word,
        reading: composita.reading,
        isTarget: true,
      ),
    ],
    jlptLevel: composita.effectiveJlptLevel ?? 5,
    source: 'synthetic',
    translation: composita.meaning,
  );
}
