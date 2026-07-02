import 'dart:async';

import 'package:client/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/api_errors.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/event_bus/subscription_spec.dart';
import 'package:uuid/uuid.dart';

/// One event stream per [SubscriptionSpec]: opens (via the shared EventBus
/// connection) a subscription with a fresh id, relays matching server
/// messages, and unsubscribes on dispose.
///
/// Subscribe/unsubscribe are fire-and-forget socket frames. There is no
/// per-frame retry: a lost connection tears down [eventBusProvider], which
/// rebuilds this provider (it watches the bus) and re-sends. Rejected
/// subscribes come back as an `error` envelope and surface as a stream error.
final eventSubscriptionsProvider = StreamProvider.autoDispose
    .family<EventBusServerMessage, SubscriptionSpec>((ref, spec) {
      final subscriptionId = const Uuid().v4();

      final controller = StreamController<EventBusServerMessage>();
      ref.onDispose(controller.close);

      final connectionFuture = ref.watch(eventBusProvider.future);

      StreamSubscription<EventBusServerMessage>? busSubscription;

      unawaited(() async {
        try {
          final connection = await connectionFuture;
          if (!ref.mounted || controller.isClosed) {
            return;
          }
          busSubscription = connection.events
              .where((event) => event.subscriptionId == subscriptionId)
              .listen((event) {
                final error = event.error;
                if (error != null) {
                  controller.safeAddError(
                    ApiErrorException.fromApiError(error),
                  );
                } else {
                  controller.safeAdd(event);
                }
              }, onError: (_) {});
          ref.onDispose(() {
            busSubscription?.cancel();
            _sendUnsubscribe(connection, subscriptionId);
          });

          connection.send(
            EventBusClientMessage(subscribe: spec.toCommand(subscriptionId)),
          );
        } catch (e, s) {
          controller.safeAddError(e, s);
          await busSubscription?.cancel();
        }
      }());

      return controller.stream;
    });

/// Best-effort unsubscribe; the socket may already be gone (which itself drops
/// the server-side subscription), so failures are ignored.
void _sendUnsubscribe(EventBusConnection connection, String subscriptionId) {
  try {
    connection.send(
      EventBusClientMessage(
        unsubscribe: UnsubscribeCommand(subscriptionId: subscriptionId),
      ),
    );
  } on Object {
    // Socket closed; nothing to clean up.
  }
}

extension<T> on StreamController<T> {
  void safeAdd(T event) {
    if (!isClosed) {
      add(event);
    }
  }

  void safeAddError(Object e, [StackTrace? s]) {
    if (!isClosed) {
      addError(e, s);
    }
  }
}
