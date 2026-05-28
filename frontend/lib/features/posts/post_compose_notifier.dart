import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/proto/posts.pbgrpc.dart';
import 'package:frontend/grpc_user_message.dart';
import 'package:frontend/features/posts/post_service_client_provider.dart';

final timelineComposeBodyControllerProvider = Provider<TextEditingController>((
  ref,
) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

@immutable
final class PostComposeSubmissionUi {
  const PostComposeSubmissionUi({required this.posting, this.submitError});

  final bool posting;

  final String? submitError;

  PostComposeSubmissionUi copyWith({
    bool? posting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return PostComposeSubmissionUi(
      posting: posting ?? this.posting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

final postComposeSubmissionProvider =
    NotifierProvider<PostComposeSubmissionNotifier, PostComposeSubmissionUi>(
      PostComposeSubmissionNotifier.new,
    );

final class PostComposeSubmissionNotifier
    extends Notifier<PostComposeSubmissionUi> {
  @override
  PostComposeSubmissionUi build() =>
      const PostComposeSubmissionUi(posting: false);

  Future<void> submit() async {
    if (state.posting) {
      return;
    }
    final body = ref.read(timelineComposeBodyControllerProvider).text.trim();
    if (body.isEmpty) {
      return;
    }
    state = const PostComposeSubmissionUi(posting: true);
    try {
      final postServiceClient = await ref.read(
        postServiceClientProvider.future,
      );
      await postServiceClient.createPost(CreatePostRequest(body: body));
      ref.read(timelineComposeBodyControllerProvider).clear();
      state = const PostComposeSubmissionUi(posting: false);
    } on Object catch (e) {
      state = PostComposeSubmissionUi(
        posting: false,
        submitError: grpcUserFacingMessage(e),
      );
    }
  }

  void clearSubmitError() {
    state = state.copyWith(clearSubmitError: true);
  }
}
