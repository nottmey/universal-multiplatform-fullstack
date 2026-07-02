import 'dart:async';

import 'package:client/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/api_base_uri_provider.dart';
import 'package:frontend/api/api_errors.dart';
import 'package:frontend/api/api_offline_retry.dart'
    show eventBusHandshakeTimeoutProvider;
import 'package:frontend/auth/authentication_state_provider.dart';
import 'package:frontend/event_bus/event_bus_socket.dart';

/// A live EventBus connection: a broadcast stream of server messages plus a
/// sink for client frames. The socket is the session — no session id/epoch.
class EventBusConnection {
  EventBusConnection({required this.events, required EventBusSocket socket})
    : _socket = socket;

  /// Broadcast so multiple subscription providers can filter the same socket.
  final Stream<EventBusServerMessage> events;
  final EventBusSocket _socket;

  void send(EventBusClientMessage message) => _socket.send(message);
}

final eventBusProvider = FutureProvider.autoDispose<EventBusConnection>((
  ref,
) async {
  final token = await ref.watch(authenticationIdTokenProvider.future);
  if (token == null || token.isEmpty) {
    throw StateError('EventBus requires a Firebase id token');
  }
  final connect = ref.watch(eventBusConnectorProvider);
  final uri = ref.watch(eventBusUriProvider)(token);

  final socket = await connect(uri);
  final broadcast = socket.messages.asBroadcastStream();
  final ready = Completer<void>();
  StreamSubscription<EventBusServerMessage>? monitorSubscription;

  ref.onDispose(() {
    monitorSubscription?.cancel();
    unawaited(socket.close());
  });

  void onSocketEnded({Object? e, StackTrace? s}) {
    if (ready.isCompleted) {
      ref.invalidateSelf();
    } else if (e != null) {
      ready.completeError(e, s);
    } else {
      ready.completeError(
        const EventBusUnavailableException(
          'EventBus closed before connectionReady',
        ),
      );
    }
  }

  try {
    monitorSubscription = broadcast.listen(
      (message) {
        if (message.connectionReady != null && !ready.isCompleted) {
          ready.complete();
        }
      },
      onError: (Object e, StackTrace s) => onSocketEnded(e: e, s: s),
      onDone: onSocketEnded,
    );
    await ready.future.timeout(ref.watch(eventBusHandshakeTimeoutProvider));
    return EventBusConnection(events: broadcast, socket: socket);
  } catch (_) {
    unawaited(monitorSubscription?.cancel());
    unawaited(socket.close());
    rethrow;
  }
  // Offline failures are retried by the ProviderScope-level retry policy
  // (offlineUnboundedRetryDelay); mid-session drops call ref.invalidateSelf().
});
