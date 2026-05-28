import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/posts.pb.dart';

/// Watches a single post subscription and shows the streamed body text.
final class PostSubscriptionFixture extends ConsumerStatefulWidget {
  const PostSubscriptionFixture({
    super.key,
    required this.postId,
    this.customBodyKey,
  });

  static const Key loadingKey = Key('fixture_loading');
  static const Key bodyKey = Key('fixture_body');
  static const Key errorKey = Key('fixture_error');

  final String postId;

  final Key? customBodyKey;

  @override
  ConsumerState<PostSubscriptionFixture> createState() =>
      _PostSubscriptionFixtureState();
}

final class _PostSubscriptionFixtureState
    extends ConsumerState<PostSubscriptionFixture> {
  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(
      eventSubscriptionsProvider(
        Subscription(post: SubscribePostRequest(postId: widget.postId)),
      ),
    );
    return subscription.when(
      data: (event) {
        if (!event.hasPost() || !event.post.hasPost()) {
          return const Text('loading', key: PostSubscriptionFixture.loadingKey);
        }
        return Text(
          event.post.post.body,
          key: widget.customBodyKey ?? PostSubscriptionFixture.bodyKey,
        );
      },
      loading: () =>
          const Text('loading', key: PostSubscriptionFixture.loadingKey),
      error: (_, _) =>
          const Text('error', key: PostSubscriptionFixture.errorKey),
    );
  }
}
