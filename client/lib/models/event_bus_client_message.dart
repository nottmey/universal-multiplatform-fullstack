import 'package:client/model_helpers.dart';
import 'package:client/models/subscribe_command.dart';
import 'package:client/models/unsubscribe_command.dart';
import 'package:meta/meta.dart';

@immutable
class EventBusClientMessage {
  const EventBusClientMessage({this.subscribe, this.unsubscribe});

  /// Converts a `Map<String, dynamic>` to an [EventBusClientMessage].
  factory EventBusClientMessage.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'EventBusClientMessage',
      json,
      () => EventBusClientMessage(
        subscribe: SubscribeCommand.maybeFromJson(
          json['subscribe'] as Map<String, dynamic>?,
        ),
        unsubscribe: UnsubscribeCommand.maybeFromJson(
          json['unsubscribe'] as Map<String, dynamic>?,
        ),
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static EventBusClientMessage? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return EventBusClientMessage.fromJson(json);
  }

  final SubscribeCommand? subscribe;
  final UnsubscribeCommand? unsubscribe;

  /// Converts an [EventBusClientMessage] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {
      'subscribe': subscribe?.toJson(),
      'unsubscribe': unsubscribe?.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([subscribe, unsubscribe]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventBusClientMessage &&
        subscribe == other.subscribe &&
        unsubscribe == other.unsubscribe;
  }
}
