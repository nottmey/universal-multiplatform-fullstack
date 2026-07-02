import 'package:client/messages/post_subscription_request.dart';
import 'package:client/messages/timeline_subscription_request.dart';
import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class SubscribeCommand {
  const SubscribeCommand({
    required this.subscriptionId,
    this.timeline,
    this.post,
  });

  /// Converts a `Map<String, dynamic>` to a [SubscribeCommand].
  factory SubscribeCommand.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'SubscribeCommand',
      json,
      () => SubscribeCommand(
        subscriptionId: json['subscriptionId'] as String,
        timeline: TimelineSubscriptionRequest.maybeFromJson(
          json['timeline'] as Map<String, dynamic>?,
        ),
        post: PostSubscriptionRequest.maybeFromJson(
          json['post'] as Map<String, dynamic>?,
        ),
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SubscribeCommand? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SubscribeCommand.fromJson(json);
  }

  final String subscriptionId;
  final TimelineSubscriptionRequest? timeline;
  final PostSubscriptionRequest? post;

  /// Converts a [SubscribeCommand] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'timeline': timeline?.toJson(),
      'post': post?.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([subscriptionId, timeline, post]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscribeCommand &&
        subscriptionId == other.subscriptionId &&
        timeline == other.timeline &&
        post == other.post;
  }
}
