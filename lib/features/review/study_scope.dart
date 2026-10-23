import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/app_database.dart';

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

/// Persists [StudyScope] in the SQLite database (scope_settings table) and
/// exposes it as a ValueNotifier so both the kanji-browser filter chips and
/// the review-session launcher observe the same live value.
///
/// On first load, migrates any existing SharedPreferences data into SQLite
/// (one-time), so the pool and review progress always survive together.
class StudyScopeRepository {
  StudyScopeRepository(this._db);

  final AppDatabase _db;

  // Old SharedPreferences keys -- used only for one-time migration.
  static const _oldCharactersKey = 'study_scope.characters';
  static const _oldCompositaCeilingKey = 'study_scope.composita_ceiling';
  static const _oldMaxCompositaPerKanjiKey = 'study_scope.max_composita_per_kanji';
  static const _oldModeKey = 'study_scope.mode';
  static const _oldJlptLevelsKey = 'study_scope.jlpt_levels';
  static const _oldCustomCharactersKey = 'study_scope.custom_characters';
  static const _migratedKey = 'study_scope.migrated_to_unified';
  static const _migratedToDbKey = 'study_scope.migrated_to_db';

  final ValueNotifier<StudyScope> scope = ValueNotifier(const StudyScope());

  /// Loads the scope from SQLite. On first run, migrates any existing
  /// SharedPreferences data (both old JLPT/Custom mode keys and the newer
  /// unified keys) into the database.
  ///
  /// [charsInLevels] is needed only for the legacy JLPT→unified migration
  /// (users who still had the old mode-based keys). Pass null on a fresh
  /// install or when JLPT data isn't loaded yet -- the migration simply
  /// skips the JLPT expansion in that case.
  Future<void> load({
    List<String> Function(Set<int> levels)? charsInLevels,
  }) async {
    // Try loading from the DB first.
    final row = await _db.loadScope();
    if (row != null) {
      scope.value = _fromRow(row);
      return;
    }

    // No DB row yet -- check SharedPreferences for data to migrate.
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_migratedToDbKey) == true) {
      // Already migrated but row missing (shouldn't happen) -- just save
      // the default empty scope.
      await _persist(scope.value);
      return;
    }

    StudyScope migrated;
    if (prefs.getBool(_migratedKey) == true) {
      // The newer unified SharedPreferences format -- read directly.
      migrated = StudyScope(
        characters:
            prefs.getStringList(_oldCharactersKey)?.toSet() ?? const {},
        compositaCeiling: prefs.getInt(_oldCompositaCeilingKey),
        maxCompositaPerKanji:
            prefs.getInt(_oldMaxCompositaPerKanjiKey) ?? 4,
      );
    } else if (prefs.containsKey(_oldModeKey) ||
        prefs.containsKey(_oldCustomCharactersKey)) {
      // Legacy JLPT/Custom mode keys -- resolve into unified set.
      migrated = _migrateFromLegacy(prefs, charsInLevels);
    } else {
      // Fresh install -- nothing to migrate.
      migrated = const StudyScope();
    }

    // Repair: if SharedPreferences was lost (e.g. debug reinstall) but
    // SQLite review data survived, re-add any characters that have review
    // progress but aren't in the pool.
    final orphans = await _db.orphanedCharacters(migrated.characters);
    if (orphans.isNotEmpty) {
      migrated = migrated.copyWith(
        characters: {...migrated.characters, ...orphans},
      );
    }

    scope.value = migrated;
    await _persist(migrated);

    // Mark done and clean up SharedPreferences keys.
    await prefs.setBool(_migratedToDbKey, true);
    for (final key in [
      _oldCharactersKey,
      _oldCompositaCeilingKey,
      _oldMaxCompositaPerKanjiKey,
      _oldModeKey,
      _oldJlptLevelsKey,
      _oldCustomCharactersKey,
      _migratedKey,
      'study_scope.rtk_max_index',
      'review.max_composita_per_kanji',
    ]) {
      await prefs.remove(key);
    }
  }

  /// Resolves legacy JLPT/Custom mode SharedPreferences into a unified scope.
  static StudyScope _migrateFromLegacy(
    SharedPreferences prefs,
    List<String> Function(Set<int> levels)? charsInLevels,
  ) {
    final modeName = prefs.getString(_oldModeKey);
    final oldCustom =
        prefs.getStringList(_oldCustomCharactersKey)?.toSet() ?? const <String>{};
    final oldJlptLevels =
        prefs.getStringList(_oldJlptLevelsKey)?.map(int.parse).toSet() ??
        const <int>{};
    final oldCeiling = prefs.getInt(_oldCompositaCeilingKey);
    final oldMaxComposita = prefs.getInt('review.max_composita_per_kanji');

    Set<String> characters;
    if (modeName == 'custom') {
      characters = oldCustom;
    } else if (modeName == 'jlpt' &&
        oldJlptLevels.isNotEmpty &&
        charsInLevels != null) {
      characters = charsInLevels(oldJlptLevels).toSet();
    } else {
      characters = oldCustom;
    }

    return StudyScope(
      characters: characters,
      compositaCeiling: oldCeiling,
      maxCompositaPerKanji: oldMaxComposita ?? 4,
    );
  }

  Future<void> update(StudyScope newScope) async {
    scope.value = newScope;
    await _persist(newScope);
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

  Future<void> _persist(StudyScope s) async {
    await _db.saveScope(
      characters: s.characters,
      compositaCeiling: s.compositaCeiling,
      maxCompositaPerKanji: s.maxCompositaPerKanji,
    );
  }

  static StudyScope _fromRow(ScopeSetting row) {
    final chars = (jsonDecode(row.characters) as List).cast<String>().toSet();
    return StudyScope(
      characters: chars,
      compositaCeiling: row.compositaCeiling,
      maxCompositaPerKanji: row.maxCompositaPerKanji,
    );
  }
}
