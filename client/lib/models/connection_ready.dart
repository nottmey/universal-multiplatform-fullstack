import 'package:meta/meta.dart';

@immutable
class ConnectionReady {
  const ConnectionReady();

  /// Converts a `Map<String, dynamic>` to a [ConnectionReady].
  factory ConnectionReady.fromJson(Map<String, dynamic> _) {
    return const ConnectionReady();
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ConnectionReady? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ConnectionReady.fromJson(json);
  }

  Map<String, dynamic> toJson() => const {};
}
