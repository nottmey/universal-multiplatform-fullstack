import 'package:client/model_helpers.dart';
import 'package:client/models/post.dart';
import 'package:meta/meta.dart';

@immutable
class PostResponse {
  const PostResponse({required this.post});

  /// Converts a `Map<String, dynamic>` to a [PostResponse].
  factory PostResponse.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'PostResponse',
      json,
      () => PostResponse(
        post: Post.fromJson(json['post'] as Map<String, dynamic>),
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PostResponse? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PostResponse.fromJson(json);
  }

  final Post post;

  /// Converts a [PostResponse] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'post': post.toJson()};
  }

  @override
  int get hashCode => post.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostResponse && post == other.post;
  }
}
