import '../../test_helpers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanjitomo/core/db/app_database.dart';
import 'package:kanjitomo/app_dependencies.dart';
import 'package:kanjitomo/features/learning/help_screen.dart';

void main() {
  testWidgets('shows an overview and opens the license page', (tester) async {
    final deps = AppDependencies(
      database: AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await tester.pumpWidget(testApp(home: HelpScreen(deps: deps)));
    await tester.pump();

    expect(find.textContaining('Kanjitomo helps'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'All licenses'),
      200,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'All licenses'));
    await tester.pumpAndSettle();

    expect(find.text('kanjitomo'), findsWidgets); // the license page's app name
  });
}
