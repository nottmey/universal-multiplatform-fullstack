import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/event_bus/subscription_spec.dart';
import 'package:frontend/utils/error_message.dart';

@immutable
final class TimelineFeedUi {
  const TimelineFeedUi({
    this.feedReady = false,
    this.postIds = const <String>[],
    this.subscriptionErrorMessage,
  });

  final bool feedReady;

  final List<String> postIds;

  final String? subscriptionErrorMessage;
}

final timelineFeedSubscriptionProvider = Provider<SubscriptionSpec>((_) {
  return const TimelineSubscriptionSpec();
});

final timelineFeedProvider =
    NotifierProvider.autoDispose<TimelineFeedNotifier, TimelineFeedUi>(
      TimelineFeedNotifier.new,
    );

final class TimelineFeedNotifier extends Notifier<TimelineFeedUi> {
  @override
  TimelineFeedUi build() {
    final timelineSubscriptionArgument = ref.watch(
      timelineFeedSubscriptionProvider,
    );
    ref.listen(
      eventSubscriptionsProvider(timelineSubscriptionArgument),
      (_, next) {
        next.when(
          data: (event) {
            final timeline = event.timeline;
            if (timeline == null) {
              return;
            }
            state = TimelineFeedUi(
              feedReady: true,
              postIds: List<String>.from(timeline.postIds),
              subscriptionErrorMessage: null,
            );
          },
          error: (error, _) {
            state = TimelineFeedUi(
              feedReady: false,
              postIds: const <String>[],
              subscriptionErrorMessage: errorMessage(error),
            );
          },
          loading: () {
            state = const TimelineFeedUi(
              feedReady: false,
              postIds: <String>[],
              subscriptionErrorMessage: null,
            );
          },
        );
      },
      fireImmediately: true,
    );

    return const TimelineFeedUi();
  }
}
