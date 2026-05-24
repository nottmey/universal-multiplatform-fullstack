import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/components/button.dart';

void main() {
  testWidgets('Button.icon disables until onPressed future completes', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Button.icon(
            key: const Key('async-icon-button'),
            tooltip: 'Action',
            onPressed: () => completer.future,
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    );

    final iconButtonFinder = find.descendant(
      of: find.byKey(const Key('async-icon-button')),
      matching: find.byType(IconButton),
    );

    IconButton iconButton() => tester.widget<IconButton>(iconButtonFinder);

    expect(iconButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('async-icon-button')));
    await tester.pump();

    expect(iconButton().onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();

    expect(iconButton().onPressed, isNotNull);
  });
}
