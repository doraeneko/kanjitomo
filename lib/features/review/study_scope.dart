import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which kind of selection currently defines "in scope". Mutually exclusive
/// -- exactly one of a JLPT-level selection, an RTK-ordinal cutoff, or a
/// user-curated custom set defines the scope at a time, not a union of
/// several.
enum StudyScopeMode { jlpt, rtk, custom }

/// Which characters are "in scope" for browsing and review. In
/// [StudyScopeMode.jlpt], scope is JLPT level membership. In
/// [StudyScopeMode.rtk], scope is an RTK-ordinal cutoff. In
/// [StudyScopeMode.custom], scope is exactly [customCharacters] -- for a
/// learner who wants to hand-pick their own study list instead of taking a
/// whole JLPT/RTK bucket. Deliberately not "empty set = everything" -- an
/// explicit "nothing selected" is a valid UI state, not a shorthand for
/// "select all".
@immutable
class StudyScope {
  final StudyScopeMode mode;
  final Set<int> jlptLevels; // subset of {1..5}, meaningful only in jlpt mode
  final int rtkMaxIndex; // meaningful only in rtk mode
  final Set<String> customCharacters; // meaningful only in custom mode
  // The hardest (numerically lowest) JLPT level composita/sentence testing
  // (C+D) is allowed to draw from, meaningful only in jlpt mode --
  // deliberately independent of jlptLevels (which kanji are being studied):
  // a learner studying N3 kanji may still want an easier or harder
  // composita ceiling than N3 itself. Null means composita/sentence
  // testing isn't enabled for this scope at all yet -- an explicit opt-in,
  // not a shorthand for "unrestricted" (see sentence_selection.dart's
  // compositaEnabled/jlptCeilingFor). Not meaningful in rtk/custom mode:
  // rtk has no composita/sentence testing surfaced in new UI at all, and
  // custom mode's composita scope is chosen per-kanji (see
  // CustomComposita), not via a level ceiling.
  final int? compositaCeiling;

  const StudyScope({
    this.mode = StudyScopeMode.jlpt,
    this.jlptLevels = const {},
    this.rtkMaxIndex = 500,
    this.customCharacters = const {},
    this.compositaCeiling,
  });

  /// jlpt mode is empty with no level selected; custom mode is empty with
  /// no characters chosen; rtk mode is never empty -- its cutoff always has
  /// a value (the slider can't go below 1).
  bool get isEmpty => switch (mode) {
    StudyScopeMode.custom => customCharacters.isEmpty,
    StudyScopeMode.jlpt => jlptLevels.isEmpty,
    StudyScopeMode.rtk => false,
  };

  /// Whether a character falls inside this scope. [jlptLevel]/[rtkIndex]
  /// are only consulted in the matching mode; [character] is only consulted
  /// in custom mode.
  bool matches({
    required String character,
    required int? jlptLevel,
    required int? rtkIndex,
    int? levelRank,
  }) {
    switch (mode) {
      case StudyScopeMode.custom:
        return customCharacters.contains(character);
      case StudyScopeMode.rtk:
        return rtkIndex != null && rtkIndex <= rtkMaxIndex;
      case StudyScopeMode.jlpt:
        if (jlptLevel == null || !jlptLevels.contains(jlptLevel)) return false;
        return true;
    }
  }

  StudyScope copyWith({
    StudyScopeMode? mode,
    Set<int>? jlptLevels,
    int? rtkMaxIndex,
    Set<String>? customCharacters,
    // Nullable field, same "leave unchanged" vs "reset to null" ambiguity
    // -- pass a value to set it, or use clearCompositaCeiling to reset to
    // "no composita testing".
    int? compositaCeiling,
    bool clearCompositaCeiling = false,
  }) {
    return StudyScope(
      mode: mode ?? this.mode,
      jlptLevels: jlptLevels ?? this.jlptLevels,
      rtkMaxIndex: rtkMaxIndex ?? this.rtkMaxIndex,
      customCharacters: customCharacters ?? this.customCharacters,
      compositaCeiling: clearCompositaCeiling
          ? null
          : (compositaCeiling ?? this.compositaCeiling),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudyScope &&
      mode == other.mode &&
      setEquals(jlptLevels, other.jlptLevels) &&
      rtkMaxIndex == other.rtkMaxIndex &&
      setEquals(customCharacters, other.customCharacters) &&
      compositaCeiling == other.compositaCeiling;

  @override
  int get hashCode => Object.hash(
    mode,
    Object.hashAllUnordered(jlptLevels),
    rtkMaxIndex,
    Object.hashAllUnordered(customCharacters),
    compositaCeiling,
  );
}

/// Persists [StudyScope] via shared_preferences (a handful of scalars plus
/// a string list -- drift would be overkill here) and exposes it as a
/// ValueNotifier so both the kanji-browser filter chips and the
/// review-session launcher observe the same live value.
class StudyScopeRepository {
  static const _modeKey = 'study_scope.mode';
  static const _jlptLevelsKey = 'study_scope.jlpt_levels';
  static const _rtkMaxIndexKey = 'study_scope.rtk_max_index';
  static const _customCharactersKey = 'study_scope.custom_characters';
  static const _compositaCeilingKey = 'study_scope.composita_ceiling';

  final ValueNotifier<StudyScope> scope = ValueNotifier(const StudyScope());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final levels = prefs.getStringList(_jlptLevelsKey)?.map(int.parse).toSet();
    // A stored "levelBased" (this mode's old name, pre-RTK-as-its-own-mode)
    // has no matching enum value anymore -- falls back to jlpt, the closest
    // equivalent, rather than crashing on an unrecognized name.
    final modeName = prefs.getString(_modeKey);
    final mode = StudyScopeMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => StudyScopeMode.jlpt,
    );
    scope.value = StudyScope(
      mode: mode,
      jlptLevels: levels ?? const {},
      rtkMaxIndex: prefs.getInt(_rtkMaxIndexKey) ?? 500,
      customCharacters:
          prefs.getStringList(_customCharactersKey)?.toSet() ?? const {},
      compositaCeiling: prefs.getInt(_compositaCeilingKey),
    );
  }

  Future<void> update(StudyScope newScope) async {
    scope.value = newScope;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, newScope.mode.name);
    await prefs.setStringList(
      _jlptLevelsKey,
      newScope.jlptLevels.map((l) => l.toString()).toList(),
    );
    await prefs.setInt(_rtkMaxIndexKey, newScope.rtkMaxIndex);
    await prefs.setStringList(
      _customCharactersKey,
      newScope.customCharacters.toList(),
    );
    if (newScope.compositaCeiling == null) {
      await prefs.remove(_compositaCeilingKey);
    } else {
      await prefs.setInt(_compositaCeilingKey, newScope.compositaCeiling!);
    }
  }
}
