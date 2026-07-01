import 'package:flutter/foundation.dart';

/// Stable widget keys shared by production UI and integration/widget tests.
class Keys {
  Keys._();

  static const Key timelineComposeBody = Key('timeline_compose_body');
  static const Key timelineComposeSubmit = Key('timeline_compose_submit');
  static const Key timelineAppBarRefresh = Key('timeline_app_bar_refresh');
  static const Key timelineEditDelete = Key('timeline_edit_delete');
  static const Key timelinePostEditorTitle = Key('timeline_post_editor_title');
  static const Key timelinePostEditorSave = Key('timeline_post_editor_save');
  static const Key timelineDeleteConfirm = Key('timeline_delete_confirm');
  static const Key timelinePostPayloadLoading = Key(
    'timeline_post_payload_loading',
  );
  static const Key timelineEmptyFeed = Key('timeline_empty_feed');
  static const Key timelineRefreshIndicator = Key('timeline_refresh_indicator');
  static const Key timelineSubscriptionReady = Key(
    'timeline_subscription_ready',
  );

  static const Key authenticationEmail = Key('authentication_email');
  static const Key authenticationPassword = Key('authentication_password');
  static const Key authenticationSignUp = Key('authentication_sign_up');
  static const Key authenticationSignIn = Key('authentication_sign_in');
  static const Key authenticationToggleMode = Key('authentication_toggle_mode');
  static const Key authenticationSignOut = Key('authentication_sign_out');
}
