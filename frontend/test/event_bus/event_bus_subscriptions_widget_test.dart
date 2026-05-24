import 'dart:async';

import 'package:async/async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/posts.pb.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';
import 'package:frontend/grpc/grpc_session_id_provider.dart';
import 'package:grpc/grpc.dart' as grpc hide ClientChannel;
// ignore: implementation_imports — same rationale as grpc_channel_provider.dart.
import 'package:grpc/src/client/channel.dart' show ClientChannel;
import 'package:mockito/mockito.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import '../mock_definitions.mocks.dart';

final class PostSubscriptionFixtureKeys {
  PostSubscriptionFixtureKeys._();

  static const Key loading = Key('fixture_loading');
  static const Key body = Key('fixture_body');
  static const Key error = Key('fixture_error');
}

final grpcChannelBumpProvider = StateProvider<int>((_) => 0);
final grpcClientBumpProvider = StateProvider<int>((_) => 0);

class MockClientChannel extends mocktail.Mock implements ClientChannel {}

/// Test double: [ResponseStream] extends [StreamView] — cannot cast a bare broadcast stream.
final class FakeEventBusResponseStream extends StreamView<Event>
    implements grpc.ResponseStream<Event> {
  FakeEventBusResponseStream(super.stream);

  @override
  Future<Map<String, String>> get headers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<Map<String, String>> get trailers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<void> cancel() async {}

  @override
  grpc.ResponseFuture<Event> get single =>
      throw UnsupportedError('FakeEventBusResponseStream.single');
}

final class ImmediateUnaryResponseFuture<T> extends DelegatingFuture<T>
    implements grpc.ResponseFuture<T> {
  ImmediateUnaryResponseFuture(super.future);

  @override
  Future<Map<String, String>> get headers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<Map<String, String>> get trailers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<void> cancel() async {}
}

sealed class RecordingLifecycleEvent {}

final class OpenedBus extends RecordingLifecycleEvent {}

final class Subscribed extends RecordingLifecycleEvent {}

final class Unsubscribed extends RecordingLifecycleEvent {}

MockClientChannel freshGrpcChannelMock() {
  final channel = MockClientChannel();
  mocktail.when(() => channel.shutdown()).thenAnswer((_) async {});
  mocktail.when(() => channel.terminate()).thenAnswer((_) async {});
  mocktail
      .when(() => channel.onConnectionStateChanged)
      .thenAnswer((_) => Stream<grpc.ConnectionState>.empty());
  return channel;
}

/// Watches a single post subscription and shows the streamed body text.
final class PostSubscriptionFixture extends ConsumerStatefulWidget {
  const PostSubscriptionFixture({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostSubscriptionFixture> createState() =>
      _PostSubscriptionFixtureState();
}

final class _PostSubscriptionFixtureState
    extends ConsumerState<PostSubscriptionFixture> {
  late final Subscription _subscribeArgument = Subscription(
    post: SubscribePostRequest(postId: widget.postId),
  );

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(
      eventSubscriptionsProvider(_subscribeArgument),
    );
    return subscription.when(
      data: (event) {
        if (!event.hasPost() || !event.post.hasPost()) {
          return const Text(
            'loading',
            key: PostSubscriptionFixtureKeys.loading,
          );
        }
        return Text(
          event.post.post.body,
          key: PostSubscriptionFixtureKeys.body,
        );
      },
      loading: () =>
          const Text('loading', key: PostSubscriptionFixtureKeys.loading),
      error: (_, _) =>
          const Text('error', key: PostSubscriptionFixtureKeys.error),
    );
  }
}

void main() {
  setUpAll(() {
    provideDummy<EventBusRequest>(EventBusRequest());
    provideDummy<grpc.CallOptions>(grpc.CallOptions());
    provideDummy<SubscribeRequest>(
      SubscribeRequest(
        subscription: Subscription(post: SubscribePostRequest(postId: '')),
      ),
    );
    provideDummy<Subscription>(
      Subscription(post: SubscribePostRequest(postId: '')),
    );
    provideDummy<UnsubscribeRequest>(UnsubscribeRequest(subscriptionId: ''));
  });

  testWidgets('eventSubscriptionsProvider lifecycle and multiplexed bus', (
    WidgetTester tester,
  ) async {
    final lifecycleTimeline = <RecordingLifecycleEvent>[];
    final subscribeCalls = <SubscribeRequest>[];
    final unsubscribeCalls = <UnsubscribeRequest>[];
    final eventBusRequests = <EventBusRequest>[];
    var eventBusInvocationCount = 0;
    StreamController<Event>? latestBusController;

    MockEventBusServiceClient freshEventBusClient() {
      final client = MockEventBusServiceClient();

      when(client.eventBus(any, options: anyNamed('options'))).thenAnswer((
        invocation,
      ) {
        eventBusInvocationCount++;
        lifecycleTimeline.add(OpenedBus());
        eventBusRequests.add(
          invocation.positionalArguments.first as EventBusRequest,
        );
        latestBusController = StreamController<Event>();
        return FakeEventBusResponseStream(latestBusController!.stream);
      });

      when(client.subscribe(any, options: anyNamed('options'))).thenAnswer((
        invocation,
      ) {
        lifecycleTimeline.add(Subscribed());
        subscribeCalls.add(
          invocation.positionalArguments.first as SubscribeRequest,
        );
        return ImmediateUnaryResponseFuture(Future<Empty>.value(Empty()));
      });

      when(client.unsubscribe(any, options: anyNamed('options'))).thenAnswer((
        invocation,
      ) {
        lifecycleTimeline.add(Unsubscribed());
        unsubscribeCalls.add(
          invocation.positionalArguments.first as UnsubscribeRequest,
        );
        return ImmediateUnaryResponseFuture(Future<Empty>.value(Empty()));
      });

      return client;
    }

    final container = ProviderContainer(
      overrides: [
        grpcSessionIdProvider.overrideWith((_) => 'pinned-session-widget-test'),
        grpcChannelProvider.overrideWith((ref) {
          ref.watch(grpcChannelBumpProvider);
          return freshGrpcChannelMock();
        }),
        eventBusServiceClientProvider.overrideWith((ref) {
          ref.watch(grpcClientBumpProvider);
          ref.watch(grpcChannelBumpProvider);
          ref.watch(grpcChannelProvider);
          return freshEventBusClient();
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PostSubscriptionFixture(postId: 'fixture-post')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(eventBusInvocationCount, 1);
    expect(subscribeCalls, hasLength(1));
    expect(subscribeCalls.single.subscription.post.postId, 'fixture-post');
    expect(subscribeCalls.single.subscription.subscriptionId, isNotEmpty);
    expect(eventBusRequests.single.context.id, 'pinned-session-widget-test');
    expect(eventBusRequests.single.context.epoch, Int64(0));
    expect(subscribeCalls.single.context.id, 'pinned-session-widget-test');
    expect(subscribeCalls.single.context.epoch, Int64(0));
    final openedIndex = lifecycleTimeline.indexWhere((e) => e is OpenedBus);
    final firstSubscribedIndex = lifecycleTimeline.indexWhere(
      (e) => e is Subscribed,
    );
    expect(openedIndex, lessThan(firstSubscribedIndex));

    final correlationId = subscribeCalls.single.subscription.subscriptionId;
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
    expect(find.byKey(PostSubscriptionFixtureKeys.body), findsOneWidget);
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

    expect(eventBusInvocationCount, 2);
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

    expect(eventBusInvocationCount, 3);
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
    expect(unsubscribeCalls.last.subscriptionId, correlationIdAfterClient);
    expect(unsubscribeCalls.last.context.id, 'pinned-session-widget-test');
  });

  test('fake multiplex delivers to derived listeners', () async {
    final latestBusController = StreamController<Event>();
    final multiplex = FakeEventBusResponseStream(
      latestBusController.stream,
    ).asBroadcastStream();
    var multiplexListenCount = 0;
    multiplex.listen((_) => multiplexListenCount++);
    var filteredCount = 0;
    multiplex
        .where((event) => event.subscriptionId == 'correlation')
        .listen((_) => filteredCount++);
    latestBusController.add(Event(subscriptionId: 'correlation'));
    await Future<void>.delayed(Duration.zero);
    expect(multiplexListenCount, 1);
    expect(filteredCount, 1);
    await latestBusController.close();
  });

  testWidgets('bumpEpoch increments connection context epoch on next client', (
    WidgetTester tester,
  ) async {
    final eventBusContexts = <ConnectionContext>[];

    final fakeClient = MockEventBusServiceClient();

    when(fakeClient.eventBus(any, options: anyNamed('options'))).thenAnswer((
      invocation,
    ) {
      eventBusContexts.add(
        (invocation.positionalArguments.first as EventBusRequest).context,
      );
      final controller = StreamController<Event>();
      return FakeEventBusResponseStream(controller.stream);
    });
    when(fakeClient.subscribe(any, options: anyNamed('options'))).thenAnswer(
      (_) => ImmediateUnaryResponseFuture(Future<Empty>.value(Empty())),
    );
    when(fakeClient.unsubscribe(any, options: anyNamed('options'))).thenAnswer(
      (_) => ImmediateUnaryResponseFuture(Future<Empty>.value(Empty())),
    );

    final container = ProviderContainer(
      overrides: [
        grpcSessionIdProvider.overrideWith((_) => 'session-stable'),
        grpcChannelProvider.overrideWith((_) => freshGrpcChannelMock()),
        eventBusServiceClientProvider.overrideWith((ref) {
          ref.watch(grpcChannelProvider);
          return fakeClient;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PostSubscriptionFixture(postId: 'epoch-post')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final epochBeforeBump = eventBusContexts.last.epoch;

    container.read(grpcConnectionEpochProvider.notifier).bumpEpoch();
    await tester.pump();

    expect(eventBusContexts.last.epoch, epochBeforeBump + Int64(1));
    expect(eventBusContexts.last.id, 'session-stable');
  });
}
