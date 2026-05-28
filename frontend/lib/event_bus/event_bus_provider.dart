import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';

typedef EventBusConnection = ({Stream<Event> stream, Future<void> established});

final eventBusProvider = Provider.autoDispose<EventBusConnection>((ref) {
  final client = ref.watch(eventBusServiceClientProvider);
  final connectionContext = ref.watch(grpcConnectionContextProvider);
  final responseStream = client.eventBus(
    EventBusRequest(context: connectionContext, subscriptions: []),
  );
  ref.onDispose(responseStream.cancel);
  return (
    stream: responseStream.asBroadcastStream(),
    established: responseStream.headers.then((_) {}),
  );
});
