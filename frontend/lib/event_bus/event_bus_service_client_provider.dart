import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/grpc/grpc_call_options_provider.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';

export 'package:frontend/grpc/grpc_connection_context_provider.dart';
export 'package:frontend/grpc/grpc_connection_epoch_provider.dart';

final eventBusServiceClientProvider = Provider((ref) {
  return EventBusServiceClient(
    ref.watch(grpcChannelProvider),
    options: ref.watch(grpcCallOptionsProvider),
  );
});
