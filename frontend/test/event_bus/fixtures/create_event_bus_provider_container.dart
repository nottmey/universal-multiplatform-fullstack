import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/event_bus/event_bus_service_client_provider.dart';
import 'package:frontend/grpc/grpc_call_options_provider.dart';
import 'package:frontend/grpc/grpc_offline_retry.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';
import 'package:frontend/grpc/grpc_session_id_provider.dart';
import 'package:grpc/grpc.dart';

import '../../fixtures/mock_client_channel.dart';
import '../../mock_definitions.mocks.dart';

/// Bumping this invalidates [eventBusServiceClientProvider] in test containers.
final eventBusClientGenerationProvider = StateProvider<int>((ref) => 0);

const Duration _fastConnectionAttemptTimeout = Duration(milliseconds: 20);

ProviderContainer createEventBusProviderContainer({
  required String sessionId,
  required MockEventBusServiceClient Function(Ref ref) eventBusClientBuilder,
  void Function(Ref ref)? onConfigureChannelOverride,
  void Function(Ref ref)? onConfigureClientOverride,
}) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      grpcConnectionAttemptTimeoutProvider.overrideWithValue(
        _fastConnectionAttemptTimeout,
      ),
      eventBusHandshakeTimeoutProvider.overrideWithValue(
        _fastConnectionAttemptTimeout,
      ),
      grpcCallOptionsProvider.overrideWith((_) async => CallOptions()),
      grpcSessionIdProvider.overrideWith((_) => sessionId),
      grpcChannelProvider.overrideWith((ref) {
        onConfigureChannelOverride?.call(ref);
        return MockClientChannel.empty();
      }),
      eventBusServiceClientProvider.overrideWith((ref) async {
        ref.watch(eventBusClientGenerationProvider);
        onConfigureClientOverride?.call(ref);
        return eventBusClientBuilder(ref);
      }),
    ],
  );
}
