import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class Post {
  const Post({
    required this.postId,
    required this.body,
    required this.postedAtMillis,
  });

  /// Converts a `Map<String, dynamic>` to a [Post].
  factory Post.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'Post',
      json,
      () => Post(
        postId: json['postId'] as String,
        body: json['body'] as String,
        postedAtMillis: json['postedAtMillis'] as int,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Post? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Post.fromJson(json);
  }

  final String postId;
  final String body;
  final int postedAtMillis;

  /// Converts a [Post] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'postId': postId, 'body': body, 'postedAtMillis': postedAtMillis};
  }

  @override
  int get hashCode => Object.hashAll([postId, body, postedAtMillis]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post &&
        postId == other.postId &&
        body == other.body &&
        postedAtMillis == other.postedAtMillis;
  }
}
