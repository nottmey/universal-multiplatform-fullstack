import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/auth/authentication_state_provider.dart';
import 'package:grpc/grpc.dart';

final grpcCallOptionsProvider = FutureProvider<CallOptions>((ref) async {
  final token = await ref.watch(authenticationIdTokenProvider.future);
  if (token == null || token.isEmpty) {
    throw StateError('gRPC call requires a Firebase id token');
  }
  return CallOptions(metadata: {'authorization': 'Bearer $token'});
});
