import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/grpc/grpc_call_options_provider.dart';
import 'package:frontend/grpc/grpc_connection_context_provider.dart';
import 'package:frontend/grpc/grpc_offline_retry.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:uuid/uuid.dart';

final eventSubscriptionsProvider = StreamProvider.autoDispose
    .family<Event, Subscription>((ref, subscriptionTemplate) {
      final subscriptionId = const Uuid().v4();

      final controller = StreamController<Event>();
      ref.onDispose(controller.close);

      final eventBusServiceClientFuture = ref.watch(
        eventBusServiceClientProvider.future,
      );
      final grpcCallOptionsFuture = ref.watch(grpcCallOptionsProvider.future);
      final eventBusFuture = ref.watch(eventBusProvider.future);

      final connectionContext = ref.watch(grpcConnectionContextProvider);
      final connectionAttemptTimeout = ref.watch(
        grpcConnectionAttemptTimeoutProvider,
      );
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

      StreamSubscription<Event>? busSubscription;

      unawaited(() async {
        try {
          final eventBusStream = await eventBusFuture;
          final client = await eventBusServiceClientFuture;
          final grpcCallOptions = await grpcCallOptionsFuture;
          final callOptionsWithConnectionAttemptTimeout = grpcCallOptions
              .mergedWith(CallOptions(timeout: connectionAttemptTimeout));
          Future<void> unsubscribeWithRetry() => offlineBoundedRetryLoop(
            shouldContinue: () => true,
            operation: () => client.unsubscribe(
              unsubscribeRpcRequest,
              options: callOptionsWithConnectionAttemptTimeout,
            ),
          );
          if (ref.mounted) {
            busSubscription = eventBusStream
                .where((event) => event.subscriptionId == subscriptionId)
                .listen(controller.safeAdd, onError: (_) {});
            ref.onDispose(() => busSubscription?.cancel());

            if (ref.mounted && !controller.isClosed) {
              ref.onDispose(() => unsubscribeWithRetry().ignore());
              await offlineBoundedRetryLoop(
                shouldContinue: () => ref.mounted,
                operation: () => client.subscribe(
                  subscribeRpcRequest,
                  options: callOptionsWithConnectionAttemptTimeout,
                ),
              );
              if (controller.isClosed) {
                // controller was closed while we subscribed,
                // onDispose unsubscribe possible happened before we subscribed,
                // so we need to trigger another unsubscribe to ensure the subscription is removed
                await unsubscribeWithRetry();
              }
            }
          }
        } on RetryLoopAborted {
          await busSubscription?.cancel();
        } catch (e, s) {
          controller.safeAddError(e, s);
          await busSubscription?.cancel();
        }
      }());

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
}
