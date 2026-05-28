import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/posts.pb.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import 'fixtures/create_event_bus_provider_container.dart';
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
              eventBusHeadersFuture: Future<Map<String, String>>.value(
                <String, String>{},
              ),
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

      test(
        'exposes GrpcError when EventBus headers fail without subscribing',
        () async {
          final subscribeCalls = <SubscribeRequest>[];
          final unsubscribeCalls = <UnsubscribeRequest>[];
          final headersCompleter = Completer<Map<String, String>>();
          final subscriptionArgument = Subscription(
            post: SubscribePostRequest(postId: 'headers-fail'),
          );
          const headersFailure = GrpcError.unavailable(
            'EventBus handshake failed',
          );

          final container = createEventBusProviderContainer(
            sessionId: 'headers-failure-session',
            eventBusClientBuilder: (_) => setupRecordingEventBusClient(
              subscribeCalls: subscribeCalls,
              unsubscribeCalls: unsubscribeCalls,
              eventBusHeadersFuture: headersCompleter.future,
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
          headersCompleter.completeError(headersFailure);
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);

          expect(subscribeCalls, isEmpty);
          expect(unsubscribeCalls, isEmpty);
          expectLastAsyncGrpcError(
            states,
            code: headersFailure.code,
            message: 'EventBus handshake failed',
          );
        },
      );

      test('exposes GrpcError when EventBus stream fails after data', () async {
        final subscribeCalls = <SubscribeRequest>[];
        final unsubscribeCalls = <UnsubscribeRequest>[];
        StreamController<Event>? busController;
        final subscriptionArgument = Subscription(
          post: SubscribePostRequest(postId: 'bus-error-post'),
        );
        const busStreamFailure = GrpcError.unavailable(
          'event bus stream failed',
        );

        final container = createEventBusProviderContainer(
          sessionId: 'bus-error-session',
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            subscribeCalls: subscribeCalls,
            unsubscribeCalls: unsubscribeCalls,
            eventBusHeadersFuture: Future<Map<String, String>>.value(
              <String, String>{},
            ),
            onEventBusStream: (controller) => busController = controller,
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
        final correlationId = subscribeCalls.single.subscription.subscriptionId;
        busController!.add(
          Event(
            subscriptionId: correlationId,
            post: SubscribePostResponse(
              post: Post(postId: 'bus-error-post', body: 'before-error'),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(states.any((state) => state.hasValue), isTrue);

        busController!.addError(busStreamFailure);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(unsubscribeCalls, isEmpty);
        expectLastAsyncGrpcError(
          states,
          code: busStreamFailure.code,
          message: 'event bus stream failed',
        );
      });
    });

    group('subscription cases', () {
      testWidgets('does not call subscribe until EventBus headers complete', (
        WidgetTester tester,
      ) async {
        final subscribeCalls = <SubscribeRequest>[];
        final headersCompleter = Completer<Map<String, String>>();
        StreamController<Event>? busController;

        final container = createEventBusProviderContainer(
          sessionId: 'delayed-headers-session',
          eventBusClientBuilder: (_) => setupRecordingEventBusClient(
            subscribeCalls: subscribeCalls,
            eventBusHeadersFuture: headersCompleter.future,
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

        headersCompleter.complete(<String, String>{});
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        expect(subscribeCalls, hasLength(1));
        expect(subscribeCalls.single.subscription.post.postId, 'delayed-post');

        await busController!.close();
      });
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
            eventBusHeadersFuture: Future<Map<String, String>>.value(
              <String, String>{},
            ),
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
            eventBusHeadersFuture: Future<Map<String, String>>.value(
              <String, String>{},
            ),
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
              eventBusHeadersFuture: Future<Map<String, String>>.value(
                <String, String>{},
              ),
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
              eventBusHeadersFuture: Future<Map<String, String>>.value(
                <String, String>{},
              ),
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
              eventBusHeadersFuture: Future<Map<String, String>>.value(
                <String, String>{},
              ),
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
