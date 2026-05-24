import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';

final eventBusProvider = Provider.autoDispose<Stream<Event>>((ref) {
  final client = ref.watch(eventBusServiceClientProvider);
  final connectionContext = ref.watch(grpcConnectionContextProvider);
  final stream = client.eventBus(
    EventBusRequest(context: connectionContext, subscriptions: []),
  );
  ref.onDispose(stream.cancel);
  return stream.asBroadcastStream();
});
