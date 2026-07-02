import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class UnsubscribeCommand {
  const UnsubscribeCommand({required this.subscriptionId});

  /// Converts a `Map<String, dynamic>` to a [UnsubscribeCommand].
  factory UnsubscribeCommand.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'UnsubscribeCommand',
      json,
      () =>
          UnsubscribeCommand(subscriptionId: json['subscriptionId'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static UnsubscribeCommand? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UnsubscribeCommand.fromJson(json);
  }

  final String subscriptionId;

  /// Converts a [UnsubscribeCommand] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'subscriptionId': subscriptionId};
  }

  @override
  int get hashCode => subscriptionId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnsubscribeCommand &&
        subscriptionId == other.subscriptionId;
  }
}
