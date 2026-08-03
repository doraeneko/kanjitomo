import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/main.dart';

void main() {
  testWidgets('App launches and shows the drawing canvas', (
    WidgetTester tester,
  ) async {
    // shared_preferences (used by StudyScopeRepository) has no platform
    // implementation registered in a plain widget test -- mock it, the
    // package's own documented pattern for this exact situation.
    SharedPreferences.setMockInitialValues({});

    // The real AppDatabase needs path_provider (unavailable here) to locate
    // its on-disk file; an in-memory database sidesteps that without
    // needing to mock the plugin channel.
    final deps = AppDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    await tester.pumpWidget(KanjitomoApp(deps: deps));

    // Startup does real I/O (asset loads) before showing LookupScreen --
    // plain tester.pump() runs in a FakeAsync zone whose virtual clock
    // never actually elapses real wall-clock time, so this needs
    // tester.runAsync() to actually finish (same gotcha as
    // stroke_order_test_helpers.dart).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(find.byKey(const Key('drawing_canvas')), findsOneWidget);
  });
}
