import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/timeline.pb.dart';
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

final timelineFeedSubscriptionProvider = Provider<Subscription>((_) {
  return Subscription(timeline: SubscribeTimelineRequest());
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
            if (!event.hasTimeline()) {
              return;
            }
            state = TimelineFeedUi(
              feedReady: true,
              postIds: List<String>.from(event.timeline.postIds),
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
