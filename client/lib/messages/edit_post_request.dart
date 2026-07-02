import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class EditPostRequest {
  const EditPostRequest({required this.body});

  /// Converts a `Map<String, dynamic>` to an [EditPostRequest].
  factory EditPostRequest.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'EditPostRequest',
      json,
      () => EditPostRequest(body: json['body'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static EditPostRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return EditPostRequest.fromJson(json);
  }

  final String body;

  /// Converts an [EditPostRequest] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'body': body};
  }

  @override
  int get hashCode => body.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditPostRequest && body == other.body;
  }
}
