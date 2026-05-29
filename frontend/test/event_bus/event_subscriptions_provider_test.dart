import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/grpc/grpc_connection_epoch_provider.dart';
import 'package:frontend/grpc/grpc_offline_retry.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/posts.pb.dart';
import 'package:frontend/proto/timeline.pb.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import 'package:fake_async/fake_async.dart';

import 'fixtures/create_event_bus_provider_container.dart';
import 'fixtures/event_bus_fake_async.dart';
import 'fixtures/event_bus_provider_harness.dart';
import 'fixtures/post_subscription_fixture.dart';
import 'fixtures/recording_lifecycle_event.dart';
import 'fixtures/register_event_bus_mockito_dummies.dart';
import 'fixtures/setup_recording_event_bus_client.dart';

final grpcChannelBumpProvider = StateProvider<int>((_) => 0);
final grpcClientBumpProvider = StateProvider<int>((_) => 0);

void expectLastAsyncGrpcError(
  List<AsyncValue<Event>> states, {
  required int code,
  required String message,
}) {
  final erroredStates = states.where((state) => state.hasError).toList();
  expect(erroredStates, isNotEmpty);
  final error = erroredStates.last.error;
  expect(error, isA<GrpcError>());
  expect((error! as GrpcError).code, code);
  expect((error as GrpcError).message, message);
}

void main() {
  setUpAll(registerEventBusMockitoDummies);

  group('eventSubscriptionsProvider', () {
    group('error cases', () {
      test(
        'exposes activation GrpcError without unsubscribing when subscribe fails',
        () async {
          final subscribeCalls = <SubscribeRequest>[];
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final subscribeCompleter = Completer<Empty>();
          final subscriptionArgument = Subscription(
            post: SubscribePostRequest(postId: 'subscribe-failure-post'),
          );
          const subscribeFailure = GrpcError.failedPrecondition(
            'no active EventBus stream',
          );

          final container = createEventBusProviderContainer(
            sessionId: 'subscribe-failure-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              subscribeCalls: subscribeCalls,
              unsubscribeCalls: unsubscribeCalls,
              subscribeResponse: (_) => subscribeCompleter.future,
            ),
          );
          addTearDown(container.dispose);

          final states = <AsyncValue<Event>>[];
          container.listen(
            eventSubscriptionsProvider(subscriptionArgument),
            (_, next) => states.add(next),
            fireImmediately: true,
          );

          await Future<void>.delayed(Duration.zero);
          subscribeCompleter.completeError(subscribeFailure);
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);

          expect(subscribeCalls, hasLength(1));
          expect(unsubscribeCalls, isEmpty);
          expectLastAsyncGrpcError(
            states,
            code: subscribeFailure.code,
            message: 'no active EventBus stream',
          );
        },
      );

      test('retries subscribe when unavailable then succeeds', () {
        fakeAsync((async) {
          var subscribeAttempts = 0;
          final subscribeCalls = <SubscribeRequest>[];
          final subscriptionArgument = Subscription(
            timeline: SubscribeTimelineRequest(),
          );

          final container = createEventBusProviderContainer(
            sessionId: 'subscribe-retry-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              subscribeCalls: subscribeCalls,
              subscribeResponse: (_) {
                subscribeAttempts++;
                if (subscribeAttempts < 2) {
                  return Future<Empty>.error(GrpcError.unavailable('offline'));
                }
                return Future<Empty>.value(Empty());
              },
            ),
          );

          try {
            final states = <AsyncValue<Event>>[];
            container.listen(
              eventSubscriptionsProvider(subscriptionArgument),
              (_, next) => states.add(next),
              fireImmediately: true,
            );

            async.flush();
            async.pumpUntil(() => subscribeAttempts >= 1);
            async.elapseOfflineRetryBackoff(failureIndex: 0);
            async.pumpUntil(() => subscribeAttempts >= 2);

            expect(subscribeAttempts, 2);
            expect(subscribeCalls, isNotEmpty);
            expect(states.where((state) => state.hasError), isEmpty);
          } finally {
            container.dispose();
          }
        });
      });

      test(
        'exposes GrpcError when EventBus never becomes ready without subscribing',
        () async {
          final subscribeCalls = <SubscribeRequest>[];
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final subscriptionArgument = Subscription(
            post: SubscribePostRequest(postId: 'connection-not-ready'),
          );
          const handshakeFailure = GrpcError.failedPrecondition(
            'EventBus handshake failed',
          );

          final container = createEventBusProviderContainer(
            sessionId: 'connection-not-ready-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              subscribeCalls: subscribeCalls,
              unsubscribeCalls: unsubscribeCalls,
              deferConnectionReady: true,
              onEventBusStream: (controller) {
                controller.addError(handshakeFailure);
              },
            ),
          );
          addTearDown(container.dispose);

          final states = <AsyncValue<Event>>[];
          container.listen(
            eventSubscriptionsProvider(subscriptionArgument),
            (_, next) => states.add(next),
            fireImmediately: true,
          );

          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);

          expect(subscribeCalls, isEmpty);
          expect(unsubscribeCalls, isEmpty);
          expectLastAsyncGrpcError(
            states,
            code: handshakeFailure.code,
            message: 'EventBus handshake failed',
          );
        },
      );

      test(
        'recovers after EventBus stream fails without surfacing subscription error',
        () {
          fakeAsync((async) {
            var eventBusOpenCount = 0;
            StreamController<Event>? latestBusController;
            final subscribeCalls = <SubscribeRequest>[];
            final subscriptionArgument = Subscription(
              timeline: SubscribeTimelineRequest(),
            );

            final container = createEventBusProviderContainer(
              sessionId: 'bus-recovery-session',
              eventBusClientBuilder: (_) => setupRecordingEventBusClient(
                subscribeCalls: subscribeCalls,
                onEventBusStream: (controller) {
                  eventBusOpenCount++;
                  latestBusController = controller;
                },
              ),
            );

            try {
              container.listen(
                eventBusProvider,
                (_, _) {},
                fireImmediately: true,
              );

              final states = <AsyncValue<Event>>[];
              container.listen(
                eventSubscriptionsProvider(subscriptionArgument),
                (_, next) => states.add(next),
                fireImmediately: true,
              );

              async.flush();
              expect(eventBusOpenCount, 1);

              final firstCorrelationId =
                  subscribeCalls.single.subscription.subscriptionId;
              latestBusController!.add(
                timelineEvent(
                  postIds: ['before-failure'],
                  subscriptionId: firstCorrelationId,
                ),
              );
              async.flush();
              expect(states.where((state) => state.hasValue), isNotEmpty);
              expect(states.where((state) => state.hasError), isEmpty);

              latestBusController!.addError(
                GrpcError.unavailable('event bus stream failed'),
              );
              async.drainPendingAsyncWork();
              async.elapseOfflineRetryBackoff(failureIndex: 0);
              async.drainPendingAsyncWork();
              async.pumpUntil(() => eventBusOpenCount > 1);

              expect(states.where((state) => state.hasError), isEmpty);
              expect(subscribeCalls.length, greaterThan(1));

              final recoveredCorrelationId =
                  subscribeCalls.last.subscription.subscriptionId;
              latestBusController!.add(
                timelineEvent(
                  postIds: ['after-recovery'],
                  subscriptionId: recoveredCorrelationId,
                ),
              );
              async.flush();

              expect(states.last.hasValue, isTrue);
              expect(states.last.value!.timeline.postIds, ['after-recovery']);
            } finally {
              container.dispose();
            }
          });
        },
      );
    });

    group('subscription cases', () {
      testWidgets(
        'does not call subscribe until EventBus connection is ready',
        (WidgetTester tester) async {
          final subscribeCalls = <SubscribeRequest>[];
          StreamController<Event>? busController;

          final container = createEventBusProviderContainer(
            sessionId: 'delayed-connection-ready-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              subscribeCalls: subscribeCalls,
              deferConnectionReady: true,
              onEventBusStream: (controller) => busController = controller,
            ),
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: PostSubscriptionFixture(postId: 'delayed-post'),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(subscribeCalls, isEmpty);

          busController!.add(Event(connectionReady: ConnectionReady()));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(subscribeCalls, hasLength(1));
          expect(
            subscribeCalls.single.subscription.post.postId,
            'delayed-post',
          );

          await busController!.close();
        },
      );
    });

    group('multiplex cases', () {
      testWidgets('stays loading when bus event has another subscription id', (
        WidgetTester tester,
      ) async {
        final subscribeCalls = <SubscribeRequest>[];
        StreamController<Event>? busController;

        final container = createEventBusProviderContainer(
          sessionId: 'wrong-correlation-session',
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            subscribeCalls: subscribeCalls,
            onEventBusStream: (controller) => busController = controller,
          ),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: PostSubscriptionFixture(postId: 'wrong-correlation-post'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        busController!.add(
          Event(
            subscriptionId: 'another-subscription-id',
            post: SubscribePostResponse(
              post: Post(
                postId: 'wrong-correlation-post',
                body: 'not-for-this-widget',
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byKey(PostSubscriptionFixture.loadingKey), findsOneWidget);
        expect(find.byKey(PostSubscriptionFixture.bodyKey), findsNothing);
      });

      testWidgets('shows each post body only for its own subscription', (
        WidgetTester tester,
      ) async {
        final subscribeCalls = <SubscribeRequest>[];
        StreamController<Event>? busController;

        final container = createEventBusProviderContainer(
          sessionId: 'dual-subscription-session',
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            subscribeCalls: subscribeCalls,
            onEventBusStream: (controller) => busController = controller,
          ),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: Row(
                  children: [
                    PostSubscriptionFixture(
                      postId: 'post-a',
                      customBodyKey: Key('fixture_body_post_a'),
                    ),
                    PostSubscriptionFixture(
                      postId: 'post-b',
                      customBodyKey: Key('fixture_body_post_b'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        expect(subscribeCalls, hasLength(2));
        expect(
          subscribeCalls
              .map((request) => request.subscription.post.postId)
              .toList(),
          containsAll(['post-a', 'post-b']),
        );

        for (final request in subscribeCalls) {
          final postId = request.subscription.post.postId;
          busController!.add(
            Event(
              subscriptionId: request.subscription.subscriptionId,
              post: SubscribePostResponse(
                post: Post(postId: postId, body: 'body-for-$postId'),
              ),
            ),
          );
        }
        await tester.pump();
        await tester.pump();

        expect(find.text('body-for-post-a'), findsOneWidget);
        expect(find.text('body-for-post-b'), findsOneWidget);
      });
    });

    group('dispose cases', () {
      test(
        'does not surface RetryLoopAborted when disposed during subscribe retries',
        () {
          fakeAsync((async) {
            var subscribeAttempts = 0;
            final subscriptionArgument = Subscription(
              timeline: SubscribeTimelineRequest(),
            );

            final container = createEventBusProviderContainer(
              sessionId: 'dispose-during-subscribe-session',
              eventBusClientBuilder: (_) => setupRecordingEventBusClient(
                subscribeResponse: (_) {
                  subscribeAttempts++;
                  return Future<Empty>.error(GrpcError.unavailable('offline'));
                },
              ),
            );

            try {
              container.listen(
                eventBusProvider,
                (_, _) {},
                fireImmediately: true,
              );

              final states = <AsyncValue<Event>>[];
              final providerSubscription = container.listen(
                eventSubscriptionsProvider(subscriptionArgument),
                (_, next) => states.add(next),
                fireImmediately: true,
              );

              async.flush();
              expect(subscribeAttempts, 1);

              providerSubscription.close();
              async.elapseOfflineRetryDelays(failureCount: boundedRetryCount);

              expect(states.where((state) => state.hasError), isEmpty);
            } finally {
              container.dispose();
            }
          });
        },
      );

      test('retries unsubscribe when unavailable then succeeds', () {
        fakeAsync((async) {
          var unsubscribeAttempts = 0;
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final subscriptionArgument = Subscription(
            timeline: SubscribeTimelineRequest(),
          );

          final container = createEventBusProviderContainer(
            sessionId: 'unsubscribe-retry-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              unsubscribeCalls: unsubscribeCalls,
              unsubscribeResponse: (_) {
                unsubscribeAttempts++;
                if (unsubscribeAttempts < 2) {
                  return Future<Empty>.error(GrpcError.unavailable('offline'));
                }
                return Future<Empty>.value(Empty());
              },
            ),
          );

          try {
            final subscription = container.listen(
              eventSubscriptionsProvider(subscriptionArgument),
              (_, _) {},
              fireImmediately: true,
            );
            async.flush();
            async.pumpUntil(() => unsubscribeAttempts == 0);
            subscription.close();
            async.flush();
            async.pumpUntil(() => unsubscribeAttempts >= 1);
            async.elapseOfflineRetryBackoff(failureIndex: 0);
            async.pumpUntil(() => unsubscribeAttempts >= 2);

            expect(unsubscribeAttempts, 2);
            expect(unsubscribeCalls, isNotEmpty);
          } finally {
            container.dispose();
          }
        });
      });

      testWidgets(
        'cancels EventBus and unsubscribes when last subscription is removed',
        (WidgetTester tester) async {
          final lifecycleTimeline = <RecordingLifecycleEvent>[];
          final subscribeCalls = <SubscribeRequest>[];
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final eventBusRequests = <EventBusRequest>[];
          StreamController<Event>? busController;

          final container = createEventBusProviderContainer(
            sessionId: 'dispose-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              lifecycleTimeline: lifecycleTimeline,
              subscribeCalls: subscribeCalls,
              unsubscribeCalls: unsubscribeCalls,
              eventBusRequests: eventBusRequests,
              onEventBusStream: (controller) => busController = controller,
            ),
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: PostSubscriptionFixture(postId: 'dispose-post'),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(eventBusRequests, hasLength(1));
          expect(subscribeCalls, hasLength(1));
          expect(lifecycleTimeline.whereType<OpenedBus>(), hasLength(1));
          expect(lifecycleTimeline.whereType<Subscribed>(), hasLength(1));
          expect(lifecycleTimeline.whereType<ClosedBus>(), isEmpty);
          expect(unsubscribeCalls, isEmpty);

          final correlationId =
              subscribeCalls.single.subscription.subscriptionId;
          busController!.add(
            Event(
              subscriptionId: correlationId,
              post: SubscribePostResponse(
                post: Post(postId: 'dispose-post', body: 'active'),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.text('active'), findsOneWidget);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(unsubscribeCalls, hasLength(1));
          expect(unsubscribeCalls.single.subscriptionId, correlationId);
          expect(lifecycleTimeline.whereType<ClosedBus>(), hasLength(1));
          expect(eventBusRequests, hasLength(1));
        },
      );
    });

    group('dispose during subscribe', () {
      testWidgets(
        'sends compensating unsubscribe when disposed during subscribe',
        (WidgetTester tester) async {
          final subscribeCalls = <SubscribeRequest>[];
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final subscribeCompleter = Completer<Empty>();

          final container = createEventBusProviderContainer(
            sessionId: 'in-flight-subscribe-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              subscribeCalls: subscribeCalls,
              unsubscribeCalls: unsubscribeCalls,
              subscribeResponse: (_) => subscribeCompleter.future,
            ),
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: PostSubscriptionFixture(postId: 'in-flight-post'),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(subscribeCalls, hasLength(1));
          expect(unsubscribeCalls, isEmpty);
          expect(find.byKey(PostSubscriptionFixture.errorKey), findsNothing);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(unsubscribeCalls, hasLength(1));
          expect(find.byKey(PostSubscriptionFixture.errorKey), findsNothing);
          expect(
            unsubscribeCalls.single.subscriptionId,
            subscribeCalls.single.subscription.subscriptionId,
          );

          subscribeCompleter.complete(Empty());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(unsubscribeCalls, hasLength(2));
          expect(
            unsubscribeCalls.last.subscriptionId,
            subscribeCalls.single.subscription.subscriptionId,
          );
        },
      );
    });

    group('reconnection cases', () {
      testWidgets(
        'streams post updates, resubscribes on reconnect, and unsubscribes on dispose',
        (WidgetTester tester) async {
          final lifecycleTimeline = <RecordingLifecycleEvent>[];
          final subscribeCalls = <SubscribeRequest>[];
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final eventBusRequests = <EventBusRequest>[];
          StreamController<Event>? latestBusController;

          final container = createEventBusProviderContainer(
            sessionId: 'pinned-session-widget-test',
            onConfigureChannelOverride: (ref) =>
                ref.watch(grpcChannelBumpProvider),
            onConfigureClientOverride: (ref) {
              ref.watch(grpcClientBumpProvider);
              ref.watch(grpcChannelBumpProvider);
              ref.watch(grpcChannelProvider);
            },
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              lifecycleTimeline: lifecycleTimeline,
              subscribeCalls: subscribeCalls,
              unsubscribeCalls: unsubscribeCalls,
              eventBusRequests: eventBusRequests,
              onEventBusStream: (busController) =>
                  latestBusController = busController,
            ),
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: PostSubscriptionFixture(postId: 'fixture-post'),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(eventBusRequests, hasLength(1));
          expect(subscribeCalls, hasLength(1));
          expect(
            subscribeCalls.single.subscription.post.postId,
            'fixture-post',
          );
          expect(subscribeCalls.single.subscription.subscriptionId, isNotEmpty);
          expect(
            eventBusRequests.single.context.id,
            'pinned-session-widget-test',
          );
          expect(eventBusRequests.single.context.epoch, Int64(0));
          expect(
            subscribeCalls.single.context.id,
            'pinned-session-widget-test',
          );
          expect(subscribeCalls.single.context.epoch, Int64(0));
          final openedIndex = lifecycleTimeline.indexWhere(
            (e) => e is OpenedBus,
          );
          final firstSubscribedIndex = lifecycleTimeline.indexWhere(
            (e) => e is Subscribed,
          );
          expect(openedIndex, lessThan(firstSubscribedIndex));

          final correlationId =
              subscribeCalls.single.subscription.subscriptionId;
          latestBusController!.add(
            Event(
              subscriptionId: correlationId,
              post: SubscribePostResponse(
                post: Post(postId: 'fixture-post', body: 'first'),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.byKey(PostSubscriptionFixture.bodyKey), findsOneWidget);
          expect(find.text('first'), findsOneWidget);

          latestBusController!.add(
            Event(
              subscriptionId: correlationId,
              post: SubscribePostResponse(
                post: Post(postId: 'fixture-post', body: 'second'),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.text('second'), findsOneWidget);

          container.read(grpcChannelBumpProvider.notifier).state++;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(eventBusRequests, hasLength(2));
          expect(subscribeCalls, hasLength(2));
          expect(unsubscribeCalls, hasLength(1));

          final reopenedIndex = lifecycleTimeline.lastIndexWhere(
            (e) => e is OpenedBus,
          );
          final secondSubscribedIndex = lifecycleTimeline.lastIndexWhere(
            (e) => e is Subscribed,
          );
          expect(reopenedIndex, lessThan(secondSubscribedIndex));

          final correlationIdAfterChannel =
              subscribeCalls.last.subscription.subscriptionId;
          latestBusController!.add(
            Event(
              subscriptionId: correlationIdAfterChannel,
              post: SubscribePostResponse(
                post: Post(postId: 'fixture-post', body: 'after-channel'),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.text('after-channel'), findsOneWidget);

          container.read(grpcClientBumpProvider.notifier).state++;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(eventBusRequests, hasLength(3));
          expect(subscribeCalls, hasLength(3));
          expect(unsubscribeCalls, hasLength(2));

          final correlationIdAfterClient =
              subscribeCalls.last.subscription.subscriptionId;
          latestBusController!.add(
            Event(
              subscriptionId: correlationIdAfterClient,
              post: SubscribePostResponse(
                post: Post(postId: 'fixture-post', body: 'after-client'),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(find.text('after-client'), findsOneWidget);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(unsubscribeCalls, hasLength(3));
          expect(
            unsubscribeCalls.last.subscriptionId,
            correlationIdAfterClient,
          );
          expect(
            unsubscribeCalls.last.context.id,
            'pinned-session-widget-test',
          );
        },
      );

      testWidgets(
        'reopens EventBus and resubscribes with higher epoch after connection epoch bump',
        (WidgetTester tester) async {
          final lifecycleTimeline = <RecordingLifecycleEvent>[];
          final subscribeCalls = <SubscribeRequest>[];
          final eventBusRequests = <EventBusRequest>[];

          final container = createEventBusProviderContainer(
            sessionId: 'session-stable',
            onConfigureClientOverride: (ref) => ref.watch(grpcChannelProvider),
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              lifecycleTimeline: lifecycleTimeline,
              subscribeCalls: subscribeCalls,
              eventBusRequests: eventBusRequests,
            ),
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: PostSubscriptionFixture(postId: 'epoch-post'),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(subscribeCalls, hasLength(1));
          expect(subscribeCalls.single.context.epoch, Int64(0));
          expect(eventBusRequests.single.context.epoch, Int64(0));

          final openedBeforeBump = lifecycleTimeline.lastIndexWhere(
            (e) => e is OpenedBus,
          );
          final subscribedBeforeBump = lifecycleTimeline.lastIndexWhere(
            (e) => e is Subscribed,
          );

          container.read(grpcConnectionEpochProvider.notifier).bumpEpoch();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));

          expect(eventBusRequests, hasLength(2));
          expect(subscribeCalls, hasLength(2));
          expect(eventBusRequests.last.context.epoch, Int64(1));
          expect(subscribeCalls.last.context.epoch, Int64(1));
          expect(eventBusRequests.last.context.id, 'session-stable');

          final openedAfterBump = lifecycleTimeline.lastIndexWhere(
            (e) => e is OpenedBus,
          );
          final subscribedAfterBump = lifecycleTimeline.lastIndexWhere(
            (e) => e is Subscribed,
          );
          expect(openedBeforeBump, lessThan(subscribedBeforeBump));
          expect(openedAfterBump, lessThan(subscribedAfterBump));
          expect(openedAfterBump, greaterThan(subscribedBeforeBump));
        },
      );
    });
  });
}
