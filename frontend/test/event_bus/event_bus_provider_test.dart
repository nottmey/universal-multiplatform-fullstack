import 'dart:async';

import 'package:client/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api_errors.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';

import 'fixtures/event_bus_test_container.dart';
import 'fixtures/fake_event_bus_socket.dart';

EventBusServerMessage timelineEvent(
  List<String> postIds, {
  String subscriptionId = 'timeline',
}) {
  return EventBusServerMessage(
    subscriptionId: subscriptionId,
    timeline: TimelineEvent(postIds: postIds),
  );
}

void main() {
  test(
    'returns a connection after connectionReady and delivers events',
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

      final connection = await container.read(eventBusProvider.future);
      final received = <EventBusServerMessage>[];
      final sub = connection.events.listen(received.add);
      socket.emit(timelineEvent(['a', 'b']));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received, [
        timelineEvent(['a', 'b']),
      ]);
    },
  );

  test('sends client frames over the socket', () async {
    late FakeEventBusSocket socket;
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      onConnect: (_, s) {
        socket = s;
        s.emitConnectionReady();
      },
    );
    addTearDown(container.dispose);

    final connection = await container.read(eventBusProvider.future);
    connection.send(
      EventBusClientMessage(
        subscribe: SubscribeCommand(
          subscriptionId: 'id',
          timeline: const TimelineSubscriptionRequest(),
        ),
      ),
    );

    expect(socket.sentMessages, hasLength(1));
    expect(socket.sentMessages.single.subscribe?.subscriptionId, 'id');
  });

  test(
    'throws EventBusUnavailableException when socket closes before ready',
    () async {
      final container = createEventBusTestContainer(
        socketBuilder: (_) => FakeEventBusSocket(),
        onConnect: (_, s) => s.endStream(),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(eventBusProvider.future),
        throwsA(isA<EventBusUnavailableException>()),
      );
    },
  );

  test('surfaces a socket error that arrives before ready', () async {
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      onConnect: (_, s) => s.emitError(
        const ApiErrorException(code: 'UNAUTHENTICATED', message: 'no'),
      ),
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(eventBusProvider.future),
      throwsA(isA<ApiErrorException>()),
    );
  });

  test('times out when connectionReady never arrives', () async {
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(eventBusProvider.future),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('throws a StateError when there is no id token', () async {
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      idToken: null,
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(eventBusProvider.future),
      throwsA(isA<StateError>()),
    );
  });

  test('propagates connect-time offline failures to the caller', () async {
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      connectThrows: (_) =>
          const EventBusUnavailableException('offline at connect'),
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(eventBusProvider.future),
      throwsA(isA<EventBusUnavailableException>()),
    );
  });

  test('closes the socket when the provider is disposed', () async {
    late FakeEventBusSocket socket;
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      onConnect: (_, s) {
        socket = s;
        s.emitConnectionReady();
      },
    );

    await container.read(eventBusProvider.future);
    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(socket.closed, isTrue);
  });

  test('invalidates and reconnects after a mid-session socket close', () async {
    final sockets = <FakeEventBusSocket>[];
    final container = createEventBusTestContainer(
      socketBuilder: (_) => FakeEventBusSocket(),
      onConnect: (_, s) {
        sockets.add(s);
        s.emitConnectionReady();
      },
    );
    addTearDown(container.dispose);

    // Keep the provider alive so invalidateSelf triggers a rebuild.
    final sub = container.listen(eventBusProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(eventBusProvider.future);
    expect(sockets, hasLength(1));

    sockets.first.endStream();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await container.read(eventBusProvider.future);

    expect(sockets, hasLength(2));
  });

  test(
    'keeps delivering to other listeners when one cancels (broadcast)',
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

      final connection = await container.read(eventBusProvider.future);
      final firstReceived = <EventBusServerMessage>[];
      final secondReceived = <EventBusServerMessage>[];
      final first = connection.events.listen(firstReceived.add);
      final second = connection.events.listen(secondReceived.add);

      socket.emit(timelineEvent(['a']));
      await Future<void>.delayed(Duration.zero);
      await first.cancel();

      socket.emit(timelineEvent(['a', 'b']));
      await Future<void>.delayed(Duration.zero);
      await second.cancel();

      expect(firstReceived, [
        timelineEvent(['a']),
      ]);
      expect(secondReceived, [
        timelineEvent(['a']),
        timelineEvent(['a', 'b']),
      ]);
    },
  );
}
