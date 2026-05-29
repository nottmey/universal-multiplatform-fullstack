import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/grpc/grpc_connection_epoch_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:grpc/grpc.dart';

import 'fixtures/create_event_bus_provider_container.dart';
import 'fixtures/event_bus_fake_async.dart';
import 'fixtures/event_bus_provider_harness.dart';
import 'fixtures/offline_event_bus_attempts.dart';
import 'fixtures/recording_lifecycle_event.dart';
import 'fixtures/register_event_bus_mockito_dummies.dart';
import 'fixtures/setup_recording_event_bus_client.dart';

void main() {
  setUpAll(registerEventBusMockitoDummies);

  group('eventBusProvider', () {
    group('success cases', () {
      test(
        'returns stream after connection_ready and delivers events to listeners',
        () async {
          StreamController<Event>? busController;

          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'success-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              onEventBusStream: (controller) => busController = controller,
            ),
          );

          final busStream = await harness.readBusStream();
          final receivedEvents = await listenForTimelineEvents(
            busStream: busStream,
            busController: busController!,
            postIds: ['post-a'],
          );

          expect(receivedEvents, hasLength(1));
          expect(receivedEvents.single.timeline.postIds, ['post-a']);
        },
      );
    });

    group('error cases', () {
      void expectEventBusConnectsAfterOfflineFailures({
        required FakeAsync async,
        required EventBusProviderHarness harness,
        required OfflineEventBusAttemptTracker attemptTracker,
        required int failuresBeforeSuccess,
      }) {
        async.waitForEventBusAfterOfflineFailures(
          connect: () => harness.readBusStream(),
          failuresBeforeSuccess: failuresBeforeSuccess,
          readAttempts: () => attemptTracker.attempts,
        );
        async.expectStableEventBusAttempts(
          expectedAttempts: failuresBeforeSuccess + 1,
          readAttempts: () => attemptTracker.attempts,
        );
      }

      test('retries when eventBus RPC throws offline until success', () {
        fakeAsync((async) {
          final attemptTracker = OfflineEventBusAttemptTracker();
          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'rpc-offline-session',
            registerCloseOnTearDown: false,
            eventBusClientBuilder: (_) => setupOfflineEventBusAttemptsClient(
              successOnAttempt: defaultOfflineFailuresBeforeSuccess + 1,
              failureMode: OfflineEventBusFailureMode.rpcThrowsUnavailable,
              tracker: attemptTracker,
            ),
          );

          try {
            expectEventBusConnectsAfterOfflineFailures(
              async: async,
              harness: harness,
              attemptTracker: attemptTracker,
              failuresBeforeSuccess: defaultOfflineFailuresBeforeSuccess,
            );

            final receivedEvents = <Event>[];
            late final Stream<Event> busStream;
            var busStreamReady = false;
            unawaited(
              harness.readBusStream().then((stream) {
                busStream = stream;
                busStreamReady = true;
              }),
            );
            async.pumpUntil(() => busStreamReady);
            final listener = busStream.listen(receivedEvents.add);
            attemptTracker.busController!.add(
              timelineEvent(postIds: ['after-retry']),
            );
            async.flush();
            expect(receivedEvents, hasLength(1));
            expect(receivedEvents.single.timeline.postIds, ['after-retry']);
            listener.cancel();
          } finally {
            harness.close();
          }
        });
      });

      test('retries when offline error arrives before connection_ready', () {
        fakeAsync((async) {
          final attemptTracker = OfflineEventBusAttemptTracker();
          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'pre-ready-error-session',
            registerCloseOnTearDown: false,
            eventBusClientBuilder: (_) => setupOfflineEventBusAttemptsClient(
              successOnAttempt: defaultOfflineFailuresBeforeSuccess + 1,
              failureMode: OfflineEventBusFailureMode.streamErrorBeforeReady,
              tracker: attemptTracker,
            ),
          );

          try {
            expectEventBusConnectsAfterOfflineFailures(
              async: async,
              harness: harness,
              attemptTracker: attemptTracker,
              failuresBeforeSuccess: defaultOfflineFailuresBeforeSuccess,
            );
          } finally {
            harness.close();
          }
        });
      });

      test('retries when stream closes before connection_ready', () {
        fakeAsync((async) {
          final attemptTracker = OfflineEventBusAttemptTracker();
          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'pre-ready-close-session',
            registerCloseOnTearDown: false,
            eventBusClientBuilder: (_) => setupOfflineEventBusAttemptsClient(
              successOnAttempt: defaultOfflineFailuresBeforeSuccess + 1,
              failureMode: OfflineEventBusFailureMode.streamCloseBeforeReady,
              tracker: attemptTracker,
            ),
          );

          try {
            expectEventBusConnectsAfterOfflineFailures(
              async: async,
              harness: harness,
              attemptTracker: attemptTracker,
              failuresBeforeSuccess: defaultOfflineFailuresBeforeSuccess,
            );
          } finally {
            harness.close();
          }
        });
      });

      test('retries when connection_ready times out until ready arrives', () {
        fakeAsync((async) {
          final attemptTracker = OfflineEventBusAttemptTracker();
          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'ready-timeout-session',
            registerCloseOnTearDown: false,
            eventBusClientBuilder: (_) => setupOfflineEventBusAttemptsClient(
              successOnAttempt: defaultOfflineFailuresBeforeSuccess + 1,
              failureMode:
                  OfflineEventBusFailureMode.readyDeferredUntilSuccessAttempt,
              tracker: attemptTracker,
            ),
          );

          try {
            expectEventBusConnectsAfterOfflineFailures(
              async: async,
              harness: harness,
              attemptTracker: attemptTracker,
              failuresBeforeSuccess: defaultOfflineFailuresBeforeSuccess,
            );
          } finally {
            harness.close();
          }
        });
      });

      test(
        'retries when eventBusHandshakeTimeout fires before connection_ready',
        () {
          fakeAsync((async) {
            const failuresBeforeSuccess = 1;
            final attemptTracker = OfflineEventBusAttemptTracker();
            final harness = createEventBusHarness(
              addTearDown,
              sessionId: 'handshake-timeout-session',
              registerCloseOnTearDown: false,
              eventBusClientBuilder: (_) => setupOfflineEventBusAttemptsClient(
                successOnAttempt: failuresBeforeSuccess + 1,
                failureMode:
                    OfflineEventBusFailureMode.readyDeferredUntilSuccessAttempt,
                tracker: attemptTracker,
              ),
            );

            try {
              expectEventBusConnectsAfterOfflineFailures(
                async: async,
                harness: harness,
                attemptTracker: attemptTracker,
                failuresBeforeSuccess: failuresBeforeSuccess,
              );
            } finally {
              harness.close();
            }
          });
        },
      );

      test('surfaces non-offline errors without retrying', () async {
        final harness = createEventBusHarness(
          addTearDown,
          sessionId: 'auth-session',
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            deferConnectionReady: true,
            onEventBusStream: (controller) {
              controller.addError(GrpcError.unauthenticated('bad token'));
            },
          ),
        );

        await expectLater(
          harness.readBusStream(),
          throwsA(
            isA<GrpcError>().having(
              (error) => error.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
      });
    });

    group('reconnection cases', () {
      test(
        'invalidates and reconnects after mid-session stream failure then delivers events',
        () async {
          var eventBusAttempts = 0;
          StreamController<Event>? latestBusController;
          final receivedEvents = <Event>[];

          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'mid-session-recovery',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              onEventBusStream: (controller) {
                eventBusAttempts++;
                latestBusController = controller;
                controller.add(Event(connectionReady: ConnectionReady()));
              },
            ),
          );

          final firstBusStream = await harness.readBusStream();
          final firstSubscription = firstBusStream.listen(
            receivedEvents.add,
            onError: (_) {},
          );
          addTearDown(firstSubscription.cancel);

          latestBusController!.add(timelineEvent(postIds: ['before-failure']));
          await pumpEventBusMicrotasks();
          expect(receivedEvents.single.timeline.postIds, ['before-failure']);

          receivedEvents.clear();
          latestBusController!.addError(GrpcError.unavailable('mid-session'));
          await pumpEventBusMicrotasks();

          expect(eventBusAttempts, greaterThan(1));

          final recoveredBusStream = await harness.readBusStream();
          final recoveredSubscription = recoveredBusStream.listen(
            receivedEvents.add,
            onError: (_) {},
          );
          addTearDown(recoveredSubscription.cancel);

          latestBusController!.add(timelineEvent(postIds: ['after-recovery']));
          await pumpEventBusMicrotasks();

          expect(receivedEvents.single.timeline.postIds, ['after-recovery']);
        },
      );
    });

    group('dispose cases', () {
      test(
        'cancels in-flight connection when provider is disposed before ready',
        () async {
          final lifecycleTimeline = <RecordingLifecycleEvent>[];

          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'dispose-before-ready',
            registerCloseOnTearDown: false,
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              lifecycleTimeline: lifecycleTimeline,
              deferConnectionReady: true,
            ),
          );

          await Future<void>.delayed(Duration.zero);
          harness.closeProviderSubscription();
          harness.close();

          expect(lifecycleTimeline.whereType<OpenedBus>(), hasLength(1));
          expect(lifecycleTimeline.whereType<ClosedBus>(), hasLength(1));
        },
      );

      test(
        'cancels when disposed before the provider future completes',
        () async {
          final lifecycleTimeline = <RecordingLifecycleEvent>[];
          final readyGate = Completer<void>();

          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'dispose-before-complete',
            registerCloseOnTearDown: false,
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              lifecycleTimeline: lifecycleTimeline,
              deferConnectionReady: true,
              onEventBusStream: (controller) {
                unawaited(
                  readyGate.future.then((_) {
                    controller.add(Event(connectionReady: ConnectionReady()));
                  }),
                );
              },
            ),
          );

          await Future<void>.delayed(Duration.zero);
          harness.closeProviderSubscription();
          harness.close();

          expect(lifecycleTimeline.whereType<OpenedBus>(), hasLength(1));
          expect(lifecycleTimeline.whereType<ClosedBus>(), hasLength(1));
        },
      );

      test('closes bus stream when no longer watched', () async {
        final lifecycleTimeline = <RecordingLifecycleEvent>[];

        final harness = createEventBusHarness(
          addTearDown,
          sessionId: 'unwatch-session',
          registerCloseOnTearDown: false,
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            lifecycleTimeline: lifecycleTimeline,
          ),
        );

        await harness.readBusStream();
        harness.closeProviderSubscription();
        await pumpEventBusMicrotasks();
        harness.close();

        expect(lifecycleTimeline.whereType<ClosedBus>(), isNotEmpty);
      });
    });

    group('dependency refresh cases', () {
      test('re-establishes stream when EventBus client is recreated', () async {
        final lifecycleTimeline = <RecordingLifecycleEvent>[];
        final eventBusRequests = <EventBusRequest>[];

        final harness = createEventBusHarness(
          addTearDown,
          sessionId: 'client-bump-session',
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            lifecycleTimeline: lifecycleTimeline,
            eventBusRequests: eventBusRequests,
          ),
        );

        await harness.readBusStream();
        expect(eventBusRequests, hasLength(1));

        final closedBeforeBump = lifecycleTimeline
            .whereType<ClosedBus>()
            .length;

        harness.container
            .read(eventBusClientGenerationProvider.notifier)
            .state++;
        await pumpEventBusMicrotasks();
        await harness.readBusStream();

        expect(eventBusRequests, hasLength(2));
        expect(
          lifecycleTimeline.whereType<ClosedBus>().length,
          greaterThan(closedBeforeBump),
        );
        expect(eventBusRequests.last.context.id, 'client-bump-session');
      });

      test(
        're-establishes stream when connection context epoch changes',
        () async {
          final lifecycleTimeline = <RecordingLifecycleEvent>[];
          final eventBusRequests = <EventBusRequest>[];

          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'epoch-bump-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              lifecycleTimeline: lifecycleTimeline,
              eventBusRequests: eventBusRequests,
            ),
          );

          await harness.readBusStream();
          expect(eventBusRequests.single.context.epoch, Int64(0));

          final closedBeforeBump = lifecycleTimeline
              .whereType<ClosedBus>()
              .length;

          harness.container
              .read(grpcConnectionEpochProvider.notifier)
              .bumpEpoch();
          await pumpEventBusMicrotasks();
          await harness.readBusStream();

          expect(eventBusRequests, hasLength(2));
          expect(eventBusRequests.last.context.epoch, Int64(1));
          expect(eventBusRequests.last.context.id, 'epoch-bump-session');
          expect(
            lifecycleTimeline.whereType<ClosedBus>().length,
            greaterThan(closedBeforeBump),
          );
        },
      );
    });

    group('broadcast cases', () {
      test(
        'keeps delivering to other listeners when one listener is cancelled',
        () async {
          StreamController<Event>? busController;

          final harness = createEventBusHarness(
            addTearDown,
            sessionId: 'broadcast-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              onEventBusStream: (controller) => busController = controller,
            ),
          );

          final busStream = await harness.readBusStream();
          final firstListenerEvents = <Event>[];
          final secondListenerEvents = <Event>[];

          final firstListener = busStream.listen(firstListenerEvents.add);
          final secondListener = busStream.listen(secondListenerEvents.add);

          busController!.add(timelineEvent(postIds: ['shared']));
          await pumpEventBusMicrotasks();
          expect(firstListenerEvents, hasLength(1));
          expect(secondListenerEvents, hasLength(1));

          await firstListener.cancel();
          firstListenerEvents.clear();
          secondListenerEvents.clear();

          busController!.add(timelineEvent(postIds: ['after-cancel']));
          await pumpEventBusMicrotasks();

          expect(firstListenerEvents, isEmpty);
          expect(secondListenerEvents, hasLength(1));
          expect(secondListenerEvents.single.timeline.postIds, [
            'after-cancel',
          ]);

          await secondListener.cancel();
        },
      );
    });
  });
}
