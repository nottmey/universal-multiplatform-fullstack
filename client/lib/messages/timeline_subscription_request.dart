import 'package:meta/meta.dart';

@immutable
class TimelineSubscriptionRequest {
  const TimelineSubscriptionRequest();

  /// Converts a `Map<String, dynamic>` to a [TimelineSubscriptionRequest].
  factory TimelineSubscriptionRequest.fromJson(Map<String, dynamic> _) {
    return const TimelineSubscriptionRequest();
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static TimelineSubscriptionRequest? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return TimelineSubscriptionRequest.fromJson(json);
  }

  Map<String, dynamic> toJson() => const {};
}
