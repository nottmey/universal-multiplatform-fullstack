import 'package:client/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api_errors.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/event_bus/subscription_spec.dart';

import 'fixtures/event_bus_test_container.dart';
import 'fixtures/fake_event_bus_socket.dart';

void main() {
  test(
    'sends a subscribe frame with a fresh id after connectionReady',
    () async {
      late FakeEventBusSocket socket;
      final container = createEventBusTestContainer(
        socketBuilder: (_) => FakeEventBusSocket(),
        onConnect: (_, s) {
          socket = s;
          s.emitConnectionReady();
        },
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        eventSubscriptionsProvider(const TimelineSubscriptionSpec()),
        (_, _) {},
      );
      addTearDown(sub.close);
      await pump();

      expect(socket.sentMessages, hasLength(1));
      final command = socket.sentMessages.single.subscribe;
      expect(command, isNotNull);
      expect(command!.timeline, isNotNull);
      expect(command.subscriptionId, isNotEmpty);
    },
  );

  test('relays only events matching the subscription id', () async {
    late FakeEventBusSocket socket;
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      onConnect: (_, s) {
        socket = s;
        s.emitConnectionReady();
      },
    );
    addTearDown(container.dispose);

    final received = <EventBusServerMessage>[];
    final sub = container.listen(
      eventSubscriptionsProvider(const PostSubscriptionSpec('p1')),
      (_, next) => next.whenData(received.add),
    );
    addTearDown(sub.close);
    await pump();

    final subscriptionId = socket.sentMessages.single.subscribe!.subscriptionId;
    socket.emit(
      EventBusServerMessage(
        subscriptionId: subscriptionId,
        post: const PostEvent(
          post: Post(postId: 'p1', body: 'mine', postedAtMillis: 1),
        ),
      ),
    );
    socket.emit(
      const EventBusServerMessage(
        subscriptionId: 'other',
        post: PostEvent(
          post: Post(postId: 'p2', body: 'theirs', postedAtMillis: 2),
        ),
      ),
    );
    await pump();

    expect(received, hasLength(1));
    expect(received.single.post?.post?.body, 'mine');
  });

  test('surfaces an error envelope as an ApiErrorException', () async {
    late FakeEventBusSocket socket;
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      onConnect: (_, s) {
        socket = s;
        s.emitConnectionReady();
      },
    );
    addTearDown(container.dispose);

    Object? error;
    final sub = container.listen(
      eventSubscriptionsProvider(const PostSubscriptionSpec('p1')),
      (_, next) => next.whenOrNull(error: (e, _) => error = e),
    );
    addTearDown(sub.close);
    await pump();

    final subscriptionId = socket.sentMessages.single.subscribe!.subscriptionId;
    socket.emit(
      EventBusServerMessage(
        subscriptionId: subscriptionId,
        error: const ApiError(
          code: 'INVALID_ARGUMENT',
          message: 'post_id is required',
        ),
      ),
    );
    await pump();

    expect(error, isA<ApiErrorException>());
    expect((error! as ApiErrorException).code, 'INVALID_ARGUMENT');
  });

  test(
    'sends an unsubscribe frame when the subscription is disposed',
    () async {
      late FakeEventBusSocket socket;
      final container = createEventBusTestContainer(
        socketBuilder: (_) => FakeEventBusSocket(),
        onConnect: (_, s) {
          socket = s;
          s.emitConnectionReady();
        },
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        eventSubscriptionsProvider(const TimelineSubscriptionSpec()),
        (_, _) {},
      );
      await pump();
      final subscriptionId =
          socket.sentMessages.single.subscribe!.subscriptionId;

      sub.close();
      await pump();

      final unsubscribe = socket.sentMessages
          .where((m) => m.unsubscribe != null)
          .toList();
      expect(unsubscribe, hasLength(1));
      expect(unsubscribe.single.unsubscribe!.subscriptionId, subscriptionId);
    },
  );

  test(
    'surfaces an error without sending subscribe when the bus never opens',
    () async {
      final container = createEventBusTestContainer(
        socketBuilder: (_) => FakeEventBusSocket(),
        onConnect: (_, s) => s.emitError(
          const ApiErrorException(code: 'UNAUTHENTICATED', message: 'no'),
        ),
      );
      addTearDown(container.dispose);

      Object? error;
      final sub = container.listen(
        eventSubscriptionsProvider(const TimelineSubscriptionSpec()),
        (_, next) => next.whenOrNull(error: (e, _) => error = e),
      );
      addTearDown(sub.close);
      await pump();

      expect(error, isA<ApiErrorException>());
    },
  );
}

/// Lets scheduled microtasks (socket connect, subscribe send) settle.
Future<void> pump() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
