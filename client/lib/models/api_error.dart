import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class ApiError {
  const ApiError({required this.code, required this.message});

  /// Converts a `Map<String, dynamic>` to an [ApiError].
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'ApiError',
      json,
      () => ApiError(
        code: json['code'] as String,
        message: json['message'] as String,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ApiError? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ApiError.fromJson(json);
  }

  final String code;
  final String message;

  /// Converts an [ApiError] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message};
  }

  @override
  int get hashCode => Object.hashAll([code, message]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiError && code == other.code && message == other.message;
  }
}
