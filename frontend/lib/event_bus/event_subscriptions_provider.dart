import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:uuid/uuid.dart';

export 'package:frontend/event_bus/event_bus_provider.dart';
export 'package:frontend/event_bus/event_bus_service_client_provider.dart';

final eventSubscriptionsProvider = StreamProvider.autoDispose
    .family<Event, Subscription>((ref, subscriptionTemplate) {
      final subscriptionId = const Uuid().v4();

      final controller = StreamController<Event>();
      ref.onDispose(controller.close);

      final eventBus = ref.watch(eventBusProvider);
      final subscription = eventBus.stream
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
      final unsubscribeRpcRequest = UnsubscribeRequest(
        context: connectionContext,
        subscriptionId: subscriptionId,
      );
      unawaited(() async {
        try {
          await eventBus.established;
          if (!controller.isClosed) {
            await client.subscribe(subscribeRpcRequest);
            if (controller.isClosed) {
              // controller was closed while we subscribed,
              // onDispose unsubscribe possible happened before we subscribed,
              // so we need to trigger another unsubscribe to ensure the subscription is removed
              await client.unsubscribe(unsubscribeRpcRequest);
            }
          }
        } catch (e, s) {
          controller.safeAddError(e, s);
          await subscription.cancel();
        }
      }());
      ref.onDispose(() => client.unsubscribe(unsubscribeRpcRequest));

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
