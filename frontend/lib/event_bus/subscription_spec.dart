import 'package:client/api.dart';
import 'package:flutter/foundation.dart';

/// A subscription request template with value equality, used as the family
/// argument for [eventSubscriptionsProvider]. Generated models are not
/// guaranteed to have stable `==`, so the app owns this small type.
@immutable
sealed class SubscriptionSpec {
  const SubscriptionSpec();

  /// Builds the wire command for a freshly minted subscription id.
  SubscribeCommand toCommand(String subscriptionId);
}

class TimelineSubscriptionSpec extends SubscriptionSpec {
  const TimelineSubscriptionSpec();

  @override
  SubscribeCommand toCommand(String subscriptionId) => SubscribeCommand(
    subscriptionId: subscriptionId,
    timeline: const TimelineSubscriptionRequest(),
  );

  @override
  bool operator ==(Object other) => other is TimelineSubscriptionSpec;

  @override
  int get hashCode => (TimelineSubscriptionSpec).hashCode;
}

class PostSubscriptionSpec extends SubscriptionSpec {
  const PostSubscriptionSpec(this.postId);

  final String postId;

  @override
  SubscribeCommand toCommand(String subscriptionId) => SubscribeCommand(
    subscriptionId: subscriptionId,
    post: PostSubscriptionRequest(postId: postId),
  );

  @override
  bool operator ==(Object other) =>
      other is PostSubscriptionSpec && other.postId == postId;

  @override
  int get hashCode => Object.hash(PostSubscriptionSpec, postId);
}
