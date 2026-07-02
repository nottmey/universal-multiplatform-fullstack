import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';

/// Invalidating the EventBus provider closes and reopens the socket, which
/// drops all server-side subscription handles and re-establishes them —
/// functionally the old epoch bump, without any session bookkeeping.
extension EventBusForceRefreshWidgetRefExtension on WidgetRef {
  Future<void> Function() get onForceRefresh => () {
    invalidate(eventBusProvider);
    return Future<void>.delayed(const Duration(milliseconds: 500));
  };
}
