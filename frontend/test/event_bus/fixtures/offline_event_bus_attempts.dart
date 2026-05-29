import 'dart:async';

import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:grpc/grpc.dart';

import '../../mock_definitions.mocks.dart';
import 'fake_event_bus_response_stream.dart';
import 'setup_recording_event_bus_client.dart';
import 'package:mockito/mockito.dart';

enum OfflineEventBusFailureMode {
  rpcThrowsUnavailable,
  streamErrorBeforeReady,
  streamCloseBeforeReady,
  readyDeferredUntilSuccessAttempt,
}

/// Counts [eventBus] mock invocations for offline-retry tests.
final class OfflineEventBusAttemptTracker {
  int attempts = 0;
  StreamController<Event>? busController;
}

MockEventBusServiceClient setupOfflineEventBusAttemptsClient({
  required int successOnAttempt,
  required OfflineEventBusFailureMode failureMode,
  OfflineEventBusAttemptTracker? tracker,
}) {
  final attemptTracker = tracker ?? OfflineEventBusAttemptTracker();

  switch (failureMode) {
    case OfflineEventBusFailureMode.rpcThrowsUnavailable:
      final client = MockEventBusServiceClient();
      when(client.eventBus(any, options: anyNamed('options'))).thenAnswer((_) {
        attemptTracker.attempts++;
        if (attemptTracker.attempts < successOnAttempt) {
          throw GrpcError.unavailable('offline');
        }
        attemptTracker.busController = StreamController<Event>();
        attemptTracker.busController!.add(
          Event(connectionReady: ConnectionReady()),
        );
        return FakeEventBusResponseStream(attemptTracker.busController!.stream);
      });
      return client;
    case OfflineEventBusFailureMode.streamErrorBeforeReady:
    case OfflineEventBusFailureMode.streamCloseBeforeReady:
    case OfflineEventBusFailureMode.readyDeferredUntilSuccessAttempt:
      return setupRecordingEventBusClient(
        deferConnectionReady: true,
        onEventBusStream: (controller) {
          attemptTracker.attempts++;
          attemptTracker.busController = controller;
          if (failureMode ==
              OfflineEventBusFailureMode.streamErrorBeforeReady) {
            if (attemptTracker.attempts < successOnAttempt) {
              controller.addError(GrpcError.unavailable('offline'));
              return;
            }
            controller.add(Event(connectionReady: ConnectionReady()));
            return;
          }
          if (failureMode ==
              OfflineEventBusFailureMode.streamCloseBeforeReady) {
            if (attemptTracker.attempts < successOnAttempt) {
              controller.close();
              return;
            }
            controller.add(Event(connectionReady: ConnectionReady()));
            return;
          }
          if (attemptTracker.attempts >= successOnAttempt) {
            controller.add(Event(connectionReady: ConnectionReady()));
          }
        },
      );
  }
}
