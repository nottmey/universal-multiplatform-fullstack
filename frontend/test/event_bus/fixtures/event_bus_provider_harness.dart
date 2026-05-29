import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/timeline.pb.dart';

import '../../mock_definitions.mocks.dart';
import 'create_event_bus_provider_container.dart';

/// Failures before the first successful [eventBus] open in offline-retry tests.
const int defaultOfflineFailuresBeforeSuccess = 2;

Future<void> pumpEventBusMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Event timelineEvent({
  required List<String> postIds,
  String subscriptionId = 'timeline',
}) {
  return Event(
    subscriptionId: subscriptionId,
    timeline: SubscribeTimelineResponse(postIds: postIds),
  );
}

Future<List<Event>> listenForTimelineEvents({
  required Stream<Event> busStream,
  required StreamController<Event> busController,
  required List<String> postIds,
}) async {
  final receivedEvents = <Event>[];
  final streamSubscription = busStream.listen(receivedEvents.add);
  busController.add(timelineEvent(postIds: postIds));
  await pumpEventBusMicrotasks();
  await streamSubscription.cancel();
  return receivedEvents;
}

/// Watches [eventBusProvider] and exposes the container for event-bus provider tests.
final class EventBusProviderHarness {
  EventBusProviderHarness({
    required String sessionId,
    required MockEventBusServiceClient Function(Ref ref) eventBusClientBuilder,
    bool watchProvider = true,
  }) : container = createEventBusProviderContainer(
         sessionId: sessionId,
         eventBusClientBuilder: eventBusClientBuilder,
       ) {
    if (watchProvider) {
      providerSubscription = container.listen(
        eventBusProvider,
        (_, _) {},
        fireImmediately: true,
      );
    }
  }

  final ProviderContainer container;
  ProviderSubscription<AsyncValue<Stream<Event>>>? providerSubscription;

  Future<Stream<Event>> readBusStream() {
    return container.read(eventBusProvider.future);
  }

  void closeProviderSubscription() {
    providerSubscription?.close();
    providerSubscription = null;
  }

  void close() {
    closeProviderSubscription();
    container.dispose();
  }
}

EventBusProviderHarness createEventBusHarness(
  void Function(void Function() tearDown) registerTearDown, {
  required String sessionId,
  required MockEventBusServiceClient Function(Ref ref) eventBusClientBuilder,
  bool watchProvider = true,
  bool registerCloseOnTearDown = true,
}) {
  final harness = EventBusProviderHarness(
    sessionId: sessionId,
    eventBusClientBuilder: eventBusClientBuilder,
    watchProvider: watchProvider,
  );
  if (registerCloseOnTearDown) {
    registerTearDown(harness.close);
  }
  return harness;
}
