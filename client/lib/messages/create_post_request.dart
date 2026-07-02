import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class CreatePostRequest {
  const CreatePostRequest({required this.body});

  /// Converts a `Map<String, dynamic>` to a [CreatePostRequest].
  factory CreatePostRequest.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'CreatePostRequest',
      json,
      () => CreatePostRequest(body: json['body'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreatePostRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return CreatePostRequest.fromJson(json);
  }

  final String body;

  /// Converts a [CreatePostRequest] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'body': body};
  }

  @override
  int get hashCode => body.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatePostRequest && body == other.body;
  }
}
