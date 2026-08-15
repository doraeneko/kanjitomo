import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's Pro unlock status via shared_preferences.
/// Mirrors the [StudyScopeRepository] pattern: a single [ValueNotifier] that
/// any screen can listen to for reactive updates.
class ProStatusRepository {
  static const _key = 'pro.unlocked';

  // TODO: revert to false before release
  final ValueNotifier<bool> isProUnlocked = ValueNotifier(true);

  Future<void> load() async {
    // TODO: revert to reading from prefs before release
    // final prefs = await SharedPreferences.getInstance();
    // isProUnlocked.value = prefs.getBool(_key) ?? false;
  }

  Future<void> setPro(bool unlocked) async {
    isProUnlocked.value = unlocked;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, unlocked);
  }
}
