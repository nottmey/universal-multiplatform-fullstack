import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/proto/likes.pbgrpc.dart';
import 'package:frontend/grpc/grpc_call_options_provider.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';

final likesServiceClientProvider = Provider((ref) {
  return LikesServiceClient(
    ref.watch(grpcChannelProvider),
    options: ref.watch(grpcCallOptionsProvider),
  );
});
