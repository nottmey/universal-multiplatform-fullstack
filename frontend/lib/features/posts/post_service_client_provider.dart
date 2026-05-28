import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/proto/posts.pbgrpc.dart';
import 'package:frontend/grpc/grpc_call_options_provider.dart';
import 'package:frontend/grpc/grpc_channel_provider.dart';

final postServiceClientProvider = FutureProvider<PostServiceClient>((
  ref,
) async {
  return PostServiceClient(
    ref.watch(grpcChannelProvider),
    options: await ref.watch(grpcCallOptionsProvider.future),
  );
});
