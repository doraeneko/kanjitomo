import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/core/first_time_dialog.dart';

/// Real asset loads (kanji_info.json, jlpt_levels.json, rtk_index.json,
/// composita.json, stroke_paths.json) need real wall-clock time inside
/// tester.runAsync() -- same gotcha as stroke_order_test_helpers.dart's
/// pumpUntilLoaded. Each test using this lives in its own file (not grouped
/// into one testWidgets block per file): confirmed directly that a second
/// runAsync-wrapped real asset load in the same test *process* can hang
/// indefinitely, so each test file gets a fresh process instead.
Future<AppDependencies> loadTestDeps(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({...ftdSuppressedPrefs});
  final deps = AppDependencies(
    database: AppDatabase.forTesting(NativeDatabase.memory()),
  );
  await tester.runAsync(() => deps.load());
  return deps;
}
