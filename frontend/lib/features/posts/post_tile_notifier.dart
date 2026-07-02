import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/api.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/event_bus/subscription_spec.dart';
import 'package:frontend/features/posts/post_editor_dialog.dart';
import 'package:frontend/features/posts/post_editor_result.dart';
import 'package:frontend/features/posts/posts_api_provider.dart';
import 'package:frontend/utils/error_message.dart';

@immutable
final class PostTileUi {
  const PostTileUi({
    required this.postId,
    this.post,
    this.isLoadingPostPayload = true,
    this.isAwaitingDeletion = false,
    this.isPostMutationInFlight = false,
    this.subscriptionErrorMessage,
    this.transientErrorMessage,
  });

  final String postId;

  final Post? post;

  final bool isLoadingPostPayload;

  final bool isAwaitingDeletion;

  final bool isPostMutationInFlight;

  final String? subscriptionErrorMessage;

  final String? transientErrorMessage;

  PostTileUi copyWith({
    Post? post,
    bool clearPost = false,
    bool? isLoadingPostPayload,
    bool? isAwaitingDeletion,
    bool? isPostMutationInFlight,
    String? subscriptionErrorMessage,
    bool clearSubscriptionError = false,
    String? transientErrorMessage,
    bool clearTransientError = false,
  }) {
    return PostTileUi(
      postId: postId,
      post: clearPost ? null : (post ?? this.post),
      isLoadingPostPayload: isLoadingPostPayload ?? this.isLoadingPostPayload,
      isAwaitingDeletion: isAwaitingDeletion ?? this.isAwaitingDeletion,
      isPostMutationInFlight:
          isPostMutationInFlight ?? this.isPostMutationInFlight,
      subscriptionErrorMessage: clearSubscriptionError
          ? null
          : (subscriptionErrorMessage ?? this.subscriptionErrorMessage),
      transientErrorMessage: clearTransientError
          ? null
          : (transientErrorMessage ?? this.transientErrorMessage),
    );
  }
}

final postTileProvider = NotifierProvider.family
    .autoDispose<PostTileNotifier, PostTileUi, String>(PostTileNotifier.new);

final class PostTileNotifier extends Notifier<PostTileUi> {
  PostTileNotifier(this.postId)
    : _eventSubscriptionArgument = PostSubscriptionSpec(postId);

  final String postId;

  final PostSubscriptionSpec _eventSubscriptionArgument;

  @override
  PostTileUi build() {
    ref.listen(
      eventSubscriptionsProvider(_eventSubscriptionArgument),
      (_, next) {
        next.when(
          data: (event) {
            final payload = event.post;
            if (payload == null) {
              return;
            }
            if (payload.post == null) {
              state = state.copyWith(
                clearPost: true,
                isLoadingPostPayload: false,
                clearSubscriptionError: true,
              );
              return;
            }
            state = state.copyWith(
              post: payload.post,
              isLoadingPostPayload: false,
              clearSubscriptionError: true,
            );
          },
          error: (error, _) {
            state = state.copyWith(
              subscriptionErrorMessage: errorMessage(error),
              isLoadingPostPayload: false,
            );
          },
          loading: () {
            state = PostTileUi(postId: postId, isLoadingPostPayload: true);
          },
        );
      },
      fireImmediately: true,
    );

    return PostTileUi(postId: postId);
  }

  void clearTransientError() {
    state = state.copyWith(clearTransientError: true);
  }

  Future<void> openEditor(BuildContext context) async {
    final post = state.post;
    if (post == null) {
      return;
    }
    final result = await showDialog<PostEditorResult>(
      context: context,
      builder: (_) => PostEditorDialog(post: post),
    );
    if (result == null || !context.mounted) {
      return;
    }
    if (result.deleted) {
      state = state.copyWith(
        isAwaitingDeletion: true,
        isPostMutationInFlight: true,
      );
      try {
        final postsApi = await ref.read(postsApiProvider.future);
        await postsApi.deletePost(postId);
      } on Object catch (error) {
        state = state.copyWith(
          isAwaitingDeletion: false,
          isPostMutationInFlight: false,
          transientErrorMessage: errorMessage(error),
        );
        return;
      }
      state = state.copyWith(isPostMutationInFlight: false);
      return;
    }
    final savedBody = result.savedBody;
    if (savedBody == null) {
      return;
    }
    state = state.copyWith(isPostMutationInFlight: true);
    try {
      final postsApi = await ref.read(postsApiProvider.future);
      await postsApi.editPost(postId, EditPostRequest(body: savedBody));
    } on Object catch (error) {
      state = state.copyWith(
        isPostMutationInFlight: false,
        transientErrorMessage: errorMessage(error),
      );
      return;
    }
    state = state.copyWith(isPostMutationInFlight: false);
  }
}
