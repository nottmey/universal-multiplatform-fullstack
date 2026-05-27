import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
import 'package:uuid/uuid.dart';

export 'package:frontend/event_bus/event_bus_provider.dart';
export 'package:frontend/event_bus/event_bus_service_client_provider.dart';

final eventSubscriptionsProvider = StreamProvider.autoDispose
    .family<Event, Subscription>((ref, subscriptionTemplate) {
      final subscriptionId = const Uuid().v4();

      final controller = StreamController<Event>();
      ref.onDispose(controller.close);

      final eventBus = ref.watch(eventBusProvider);
      final subscription = eventBus
          .where((event) => event.subscriptionId == subscriptionId)
          .listen(
            controller.safeAdd,
            onError: controller.safeAddError,
            onDone: controller.safeClose,
          );
      ref.onDispose(subscription.cancel);

      final client = ref.watch(eventBusServiceClientProvider);
      final connectionContext = ref.watch(grpcConnectionContextProvider);
      final subscriptionPayload = subscriptionTemplate.clone()
        ..subscriptionId = subscriptionId;
      final subscribeRpcRequest = SubscribeRequest(
        context: connectionContext,
        subscription: subscriptionPayload,
      );
      // TODO: await the opening of the event bus before subscribing, maybe Future<Steam>?
      scheduleMicrotask(() {
        client.subscribe(subscribeRpcRequest).catchError((e, s) async {
          await subscription.cancel();
          if (!controller.isClosed) {
            controller.addError(e, s);
            await controller.close();
          }
          return Empty();
        });
      });
      ref.onDispose(() {
        unawaited(
          client
              .unsubscribe(
                UnsubscribeRequest(
                  context: connectionContext,
                  subscriptionId: subscriptionId,
                ),
              )
              .catchError((_) => Empty()),
        );
      });

      return controller.stream;
    });

extension<T> on StreamController<T> {
  void safeAdd(T event) {
    if (!isClosed) {
      add(event);
    }
  }

  void safeAddError(Object e, StackTrace s) {
    if (!isClosed) {
      addError(e, s);
    }
  }

  void safeClose() {
    if (!isClosed) {
      close();
    }
  }
}
