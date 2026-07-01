import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/auth/ensure_anonymous_authentication.dart';
import 'package:frontend/firebase/initialize_firebase.dart';
import 'package:frontend/keys.dart';
import 'package:frontend/social_example_app.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'sign up, timeline post survives rebuild refresh edit delete, sign out',
    ($) async {
      await initializeFirebase();
      await ensureAnonymousAuthentication(FirebaseAuth.instance);
      await $.pumpWidget(const SocialExampleApp());
      await $.pump();

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final email = 'patrol_$stamp@example.com';
      const password = 'patrol-password';

      await $(Keys.authenticationEmail).waitUntilVisible();
      await $(Keys.authenticationEmail).enterText(email);
      await $(Keys.authenticationPassword).enterText(password);
      await $(Keys.authenticationSignUp).tap();

      await $(
        Keys.timelineSubscriptionReady,
      ).waitUntilVisible(timeout: const Duration(seconds: 30));

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

      await $.pumpWidget(const SizedBox.shrink());
      await $.pump();
      await $.pumpWidget(const SocialExampleApp());
      await $.pump();

      await $(
        Keys.timelineSubscriptionReady,
      ).waitUntilVisible(timeout: const Duration(seconds: 30));

      await $(
        editedBody,
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
      expect(find.byKey(Keys.timelinePostPayloadLoading), findsNothing);

      await $(
        Keys.timelineAppBarRefresh,
      ).tap(settlePolicy: SettlePolicy.noSettle);
      await $(
        editedBody,
      ).waitUntilVisible(timeout: const Duration(seconds: 60));
      await $.pumpAndSettle();

      expect(find.text(editedBody), findsOneWidget);

      await $(editedBody).tap();
      await $(Keys.timelinePostEditorTitle).waitUntilVisible();
      await $(Keys.timelineEditDelete).tap();
      await $(Keys.timelineDeleteConfirm).waitUntilVisible();
      await $(Keys.timelineDeleteConfirm).tap();

      await $(
        Keys.timelineEmptyFeed,
      ).waitUntilVisible(timeout: const Duration(seconds: 60));
      expect(find.text(editedBody), findsNothing);

      await $(Keys.authenticationSignOut).tap();
      await $(Keys.authenticationEmail).waitUntilVisible();
    },
  );
}
