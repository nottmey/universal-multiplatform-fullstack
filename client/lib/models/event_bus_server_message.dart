import 'package:client/model_helpers.dart';
import 'package:client/models/api_error.dart';
import 'package:client/models/connection_ready.dart';
import 'package:client/models/post_event.dart';
import 'package:client/models/timeline_event.dart';
import 'package:meta/meta.dart';

@immutable
class EventBusServerMessage {
  const EventBusServerMessage({
    this.subscriptionId,
    this.connectionReady,
    this.timeline,
    this.post,
    this.error,
  });

  /// Converts a `Map<String, dynamic>` to an [EventBusServerMessage].
  factory EventBusServerMessage.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'EventBusServerMessage',
      json,
      () => EventBusServerMessage(
        subscriptionId: json['subscriptionId'] as String?,
        connectionReady: ConnectionReady.maybeFromJson(
          json['connectionReady'] as Map<String, dynamic>?,
        ),
        timeline: TimelineEvent.maybeFromJson(
          json['timeline'] as Map<String, dynamic>?,
        ),
        post: PostEvent.maybeFromJson(json['post'] as Map<String, dynamic>?),
        error: ApiError.maybeFromJson(json['error'] as Map<String, dynamic>?),
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static EventBusServerMessage? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return EventBusServerMessage.fromJson(json);
  }

  final String? subscriptionId;
  final ConnectionReady? connectionReady;
  final TimelineEvent? timeline;
  final PostEvent? post;
  final ApiError? error;

  /// Converts an [EventBusServerMessage] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'connectionReady': connectionReady?.toJson(),
      'timeline': timeline?.toJson(),
      'post': post?.toJson(),
      'error': error?.toJson(),
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([subscriptionId, connectionReady, timeline, post, error]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventBusServerMessage &&
        subscriptionId == other.subscriptionId &&
        connectionReady == other.connectionReady &&
        timeline == other.timeline &&
        post == other.post &&
        error == other.error;
  }
}
