import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';
import 'package:frontend/grpc/grpc_session_id_provider.dart';

import '../../fixtures/mock_client_channel.dart';
import '../../mock_definitions.mocks.dart';

ProviderContainer createEventBusProviderContainer({
  required String sessionId,
  required MockEventBusServiceClient Function(Ref ref) eventBusClientBuilder,
  void Function(Ref ref)? onConfigureChannelOverride,
  void Function(Ref ref)? onConfigureClientOverride,
}) {
  return ProviderContainer(
    overrides: [
      grpcSessionIdProvider.overrideWith((_) => sessionId),
      grpcChannelProvider.overrideWith((ref) {
        onConfigureChannelOverride?.call(ref);
        return MockClientChannel.empty();
      }),
      eventBusServiceClientProvider.overrideWith((ref) {
        onConfigureClientOverride?.call(ref);
        return eventBusClientBuilder(ref);
      }),
    ],
  );
}
