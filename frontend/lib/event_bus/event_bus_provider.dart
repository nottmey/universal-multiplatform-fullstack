import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:grpc/grpc.dart';

typedef EventBusConnection = ({Stream<Event> stream, Future<void> established});

const Duration _connectionReadyTimeout = Duration(seconds: 10);

final eventBusProvider = FutureProvider.autoDispose<EventBusConnection>((
  ref,
) async {
  final client = await ref.watch(eventBusServiceClientProvider.future);
  final connectionContext = ref.watch(grpcConnectionContextProvider);
  final responseStream = client.eventBus(
    EventBusRequest(context: connectionContext),
  );
  final broadcast = responseStream.asBroadcastStream();
  final connectionReady = Completer<void>();
  final handshakeSubscription = broadcast.listen(
    (event) {
      if (event.hasConnectionReady() && !connectionReady.isCompleted) {
        connectionReady.complete();
      }
    },
    onError: (error, stackTrace) {
      if (!connectionReady.isCompleted) {
        connectionReady.completeError(error, stackTrace);
      }
    },
    onDone: () {
      if (!connectionReady.isCompleted) {
        connectionReady.completeError(
          GrpcError.unavailable('EventBus closed before connection_ready'),
        );
      }
    },
  );
  ref.onDispose(() {
    handshakeSubscription.cancel();
    responseStream.cancel();
  });
  return (
    stream: broadcast,
    established: connectionReady.future.timeout(_connectionReadyTimeout),
  );
});
