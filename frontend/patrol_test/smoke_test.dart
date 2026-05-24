import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/keys.dart';
import 'package:frontend/social_example_app.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'timeline post survives provider rebuild, then refresh, edit, delete',
    ($) async {
      await $.pumpWidget(const SocialExampleApp());
      await $.pump();

      await $(
        Keys.timelineRefreshIndicator,
      ).waitUntilVisible(timeout: const Duration(seconds: 120));

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final initialBody = 'patrol_e2e_$stamp';
      final editedBody = '${initialBody}_edited';

      await $(Keys.timelineComposeBody).waitUntilVisible();
      await $(Keys.timelineComposeBody).enterText(initialBody);
      await $(Keys.timelineComposeSubmit).tap();

      await $(initialBody).waitUntilVisible();
      await $(initialBody).tap();

      await $(Keys.timelinePostEditorTitle).waitUntilVisible();
      await $(AlertDialog).$(TextField).enterText(editedBody);
      await $(Keys.timelinePostEditorSave).tap();

      await $(editedBody).waitUntilVisible();

      await $(
        find.descendant(
          of: find.ancestor(
            of: find.text(editedBody),
            matching: find.byType(ListTile),
          ),
          matching: find.byKey(Keys.timelinePostLike),
        ),
      ).tap(settlePolicy: SettlePolicy.noSettle);
      await $.pump(const Duration(milliseconds: 500));
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text(editedBody),
            matching: find.byType(ListTile),
          ),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // rebuild the app like a full reload (backend keeps data)
      await $.pumpWidget(const SizedBox.shrink());
      await $.pump();
      await $.pumpWidget(const SocialExampleApp());
      await $.pump();

      await $(
        Keys.timelineRefreshIndicator,
      ).waitUntilVisible(timeout: const Duration(seconds: 120));

      await $(
        editedBody,
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
      expect(find.byKey(Keys.timelinePostPayloadLoading), findsNothing);
      final editedPostListTile = find.ancestor(
        of: find.text(editedBody),
        matching: find.byType(ListTile),
      );
      await $(
        find.descendant(
          of: editedPostListTile,
          matching: find.byKey(Keys.timelinePostLike),
        ),
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
      expect(
        find.descendant(of: editedPostListTile, matching: find.text('1')),
        findsOneWidget,
      );

      await $(
        Keys.timelineAppBarRefresh,
      ).tap(settlePolicy: SettlePolicy.noSettle);
      await $(
        editedBody,
      ).waitUntilVisible(timeout: const Duration(seconds: 60));
      await $(
        find.descendant(
          of: editedPostListTile,
          matching: find.byKey(Keys.timelinePostLike),
        ),
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
      await $.pumpAndSettle();

      expect(find.text(editedBody), findsOneWidget);
      expect(
        find.descendant(of: editedPostListTile, matching: find.text('1')),
        findsOneWidget,
      );

      await $(editedBody).tap();
      await $(Keys.timelinePostEditorTitle).waitUntilVisible();
      await $(Keys.timelineEditDelete).tap();
      await $(Keys.timelineDeleteConfirm).waitUntilVisible();
      await $(Keys.timelineDeleteConfirm).tap();

      await $(
        Keys.timelineEmptyFeed,
      ).waitUntilVisible(timeout: const Duration(seconds: 60));
      expect(find.text(editedBody), findsNothing);
      expect(find.byKey(Keys.timelinePostLike), findsNothing);
    },
  );
}
