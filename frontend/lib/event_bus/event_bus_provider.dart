import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/grpc/grpc_connection_context_provider.dart';
import 'package:frontend/grpc/grpc_offline_retry.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:grpc/grpc.dart';

final eventBusProvider = FutureProvider.autoDispose<Stream<Event>>((
  Ref ref,
) async {
  final client = await ref.watch(eventBusServiceClientProvider.future);
  final context = ref.watch(grpcConnectionContextProvider);
  final response = client.eventBus(EventBusRequest(context: context));
  final broadcast = response.asBroadcastStream();
  final ready = Completer<void>();
  StreamSubscription<Event>? monitorSubscription;

  ref.onDispose(() {
    monitorSubscription?.cancel();
    unawaited(response.cancel());
  });

  void onEventBusEnded({Object? e, StackTrace? s}) {
    if (ready.isCompleted) {
      ref.invalidateSelf();
    } else if (e != null) {
      ready.completeError(e, s);
    } else {
      ready.completeError(
        GrpcError.unavailable('EventBus closed before connection_ready'),
      );
    }
  }

  try {
    monitorSubscription = broadcast.listen(
      (event) {
        if (event.hasConnectionReady() && !ready.isCompleted) {
          ready.complete();
        }
      },
      onError: (e, s) => onEventBusEnded(e: e, s: s),
      onDone: onEventBusEnded,
    );
    await ready.future.timeout(ref.watch(eventBusHandshakeTimeoutProvider));
    return broadcast;
  } catch (error) {
    unawaited(monitorSubscription?.cancel());
    unawaited(response.cancel());
    rethrow;
  }
}, retry: offlineUnboundedRetryDelay);
