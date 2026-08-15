import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which characters are "in scope" for browsing and review -- a single
/// unified pool of explicitly-added kanji. No automatic introduction;
/// users add kanji explicitly (by JLPT batch, RTK batch, or drawing) and
/// remove them explicitly. Deliberately not "empty set = everything" --
/// an explicit "nothing selected" is a valid UI state, not a shorthand
/// for "select all".
@immutable
class StudyScope {
  final Set<String> characters; // the unified pool
  // The hardest (numerically lowest) JLPT level composita/sentence testing
  // (C+D) is allowed to draw from. Null means composita/sentence testing
  // isn't enabled for this scope at all yet.
  final int? compositaCeiling;
  // How many composita words to auto-select per kanji when batch-adding.
  final int maxCompositaPerKanji;

  const StudyScope({
    this.characters = const {},
    this.compositaCeiling,
    this.maxCompositaPerKanji = 4,
  });

  bool get isEmpty => characters.isEmpty;

  /// Whether a character falls inside this scope -- simple set membership.
  bool matches({required String character}) {
    return characters.contains(character);
  }

  StudyScope copyWith({
    Set<String>? characters,
    int? compositaCeiling,
    bool clearCompositaCeiling = false,
    int? maxCompositaPerKanji,
  }) {
    return StudyScope(
      characters: characters ?? this.characters,
      compositaCeiling: clearCompositaCeiling
          ? null
          : (compositaCeiling ?? this.compositaCeiling),
      maxCompositaPerKanji: maxCompositaPerKanji ?? this.maxCompositaPerKanji,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudyScope &&
      setEquals(characters, other.characters) &&
      compositaCeiling == other.compositaCeiling &&
      maxCompositaPerKanji == other.maxCompositaPerKanji;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(characters),
    compositaCeiling,
    maxCompositaPerKanji,
  );
}

/// Persists [StudyScope] via shared_preferences and exposes it as a
/// ValueNotifier so both the kanji-browser filter chips and the
/// review-session launcher observe the same live value.
class StudyScopeRepository {
  // New unified keys.
  static const _charactersKey = 'study_scope.characters';
  static const _compositaCeilingKey = 'study_scope.composita_ceiling';
  static const _maxCompositaPerKanjiKey = 'study_scope.max_composita_per_kanji';

  // Old keys used for migration detection.
  static const _oldModeKey = 'study_scope.mode';
  static const _oldJlptLevelsKey = 'study_scope.jlpt_levels';
  static const _oldCustomCharactersKey = 'study_scope.custom_characters';
  static const _migratedKey = 'study_scope.migrated_to_unified';

  final ValueNotifier<StudyScope> scope = ValueNotifier(const StudyScope());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Already using the new format?
    if (prefs.getBool(_migratedKey) == true) {
      scope.value = StudyScope(
        characters:
            prefs.getStringList(_charactersKey)?.toSet() ?? const {},
        compositaCeiling: prefs.getInt(_compositaCeilingKey),
        maxCompositaPerKanji: prefs.getInt(_maxCompositaPerKanjiKey) ?? 4,
      );
      return;
    }

    // Fresh install -- no old keys either.
    if (!prefs.containsKey(_oldModeKey) &&
        !prefs.containsKey(_oldCustomCharactersKey)) {
      await prefs.setBool(_migratedKey, true);
      return;
    }

    // Migration needed -- will be completed in migrateIfNeeded().
    // Load what we can for now (custom characters are directly usable).
    final oldCustom =
        prefs.getStringList(_oldCustomCharactersKey)?.toSet() ?? const <String>{};
    final oldCeiling = prefs.getInt(_compositaCeilingKey);
    // Also check for the old max-composita key from review prefs.
    final oldMaxComposita = prefs.getInt('review.max_composita_per_kanji');
    scope.value = StudyScope(
      characters: oldCustom,
      compositaCeiling: oldCeiling,
      maxCompositaPerKanji: oldMaxComposita ?? 4,
    );
  }

  /// One-time migration from old JLPT/Custom mode-based keys to the unified
  /// pool. Must be called after JSON repositories have loaded (needs
  /// jlptLevels to resolve JLPT level selections into character sets).
  Future<void> migrateIfNeeded({
    required List<String> Function(Set<int> levels) charsInLevels,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final modeName = prefs.getString(_oldModeKey);
    final oldCustom =
        prefs.getStringList(_oldCustomCharactersKey)?.toSet() ?? const <String>{};
    final oldJlptLevels =
        prefs.getStringList(_oldJlptLevelsKey)?.map(int.parse).toSet() ??
        const <int>{};
    final oldCeiling = prefs.getInt(_compositaCeilingKey);
    final oldMaxComposita = prefs.getInt('review.max_composita_per_kanji');

    Set<String> characters;
    if (modeName == 'custom') {
      // Custom mode: keep the hand-picked set.
      characters = oldCustom;
    } else if (modeName == 'jlpt' && oldJlptLevels.isNotEmpty) {
      // JLPT mode: resolve levels into actual characters.
      characters = charsInLevels(oldJlptLevels).toSet();
    } else {
      // RTK or fresh -- start empty (RTK was hidden from UI anyway).
      characters = oldCustom;
    }

    final migrated = StudyScope(
      characters: characters,
      compositaCeiling: oldCeiling,
      maxCompositaPerKanji: oldMaxComposita ?? 4,
    );
    scope.value = migrated;
    await _persist(prefs, migrated);
    await prefs.setBool(_migratedKey, true);

    // Clean up old keys.
    await prefs.remove(_oldModeKey);
    await prefs.remove(_oldJlptLevelsKey);
    await prefs.remove(_oldCustomCharactersKey);
    await prefs.remove('study_scope.rtk_max_index');
    await prefs.remove('review.max_composita_per_kanji');
  }

  Future<void> update(StudyScope newScope) async {
    scope.value = newScope;
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, newScope);
  }

  /// Convenience: add characters to the pool.
  Future<void> addCharacters(Set<String> chars) async {
    if (chars.isEmpty) return;
    final current = scope.value;
    await update(current.copyWith(
      characters: {...current.characters, ...chars},
    ));
  }

  /// Convenience: remove characters from the pool.
  Future<void> removeCharacters(Set<String> chars) async {
    if (chars.isEmpty) return;
    final current = scope.value;
    await update(current.copyWith(
      characters: current.characters.difference(chars),
    ));
  }

  static Future<void> _persist(SharedPreferences prefs, StudyScope s) async {
    await prefs.setStringList(_charactersKey, s.characters.toList());
    if (s.compositaCeiling == null) {
      await prefs.remove(_compositaCeilingKey);
    } else {
      await prefs.setInt(_compositaCeilingKey, s.compositaCeiling!);
    }
    await prefs.setInt(_maxCompositaPerKanjiKey, s.maxCompositaPerKanji);
  }
}
