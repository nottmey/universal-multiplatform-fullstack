import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class PostSubscriptionRequest {
  const PostSubscriptionRequest({required this.postId});

  /// Converts a `Map<String, dynamic>` to a [PostSubscriptionRequest].
  factory PostSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'PostSubscriptionRequest',
      json,
      () => PostSubscriptionRequest(postId: json['postId'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PostSubscriptionRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PostSubscriptionRequest.fromJson(json);
  }

  final String postId;

  /// Converts a [PostSubscriptionRequest] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'postId': postId};
  }

  @override
  int get hashCode => postId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostSubscriptionRequest && postId == other.postId;
  }
}
