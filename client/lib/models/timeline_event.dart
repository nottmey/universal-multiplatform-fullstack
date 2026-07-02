import 'package:client/model_helpers.dart';
import 'package:meta/meta.dart';

@immutable
class TimelineEvent {
  const TimelineEvent({required this.postIds});

  /// Converts a `Map<String, dynamic>` to a [TimelineEvent].
  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return parseFromJson(
      'TimelineEvent',
      json,
      () => TimelineEvent(postIds: (json['postIds'] as List).cast<String>()),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static TimelineEvent? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return TimelineEvent.fromJson(json);
  }

  final List<String> postIds;

  /// Converts a [TimelineEvent] to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() {
    return {'postIds': postIds};
  }

  @override
  int get hashCode => listHash(postIds).hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineEvent && listsEqual(postIds, other.postIds);
  }
}
