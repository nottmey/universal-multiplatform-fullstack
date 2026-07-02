import 'package:client/model_helpers.dart';
import 'package:client/models/post.dart';
import 'package:meta/meta.dart';

@immutable
class PostEvent {
  const PostEvent({this.post});

  /// Converts a `Map<String, dynamic>` to a [PostEvent].
  factory PostEvent.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'PostEvent',
      json,
      () => PostEvent(
        post: Post.maybeFromJson(json['post'] as Map<String, dynamic>?),
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PostEvent? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PostEvent.fromJson(json);
  }

  final Post? post;

  /// Converts a [PostEvent] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'post': post?.toJson()};
  }

  @override
  int get hashCode => post.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostEvent && post == other.post;
  }
}
