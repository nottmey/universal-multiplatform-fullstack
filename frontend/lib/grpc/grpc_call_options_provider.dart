import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/auth/authentication_state_provider.dart';
import 'package:grpc/grpc.dart';

final grpcCallOptionsProvider = Provider<CallOptions>((ref) {
  // TODO: better make this a future provider
  final idToken = ref.watch(authenticationIdTokenProvider);
  return idToken.when(
    data: (token) {
      if (token == null || token.isEmpty) {
        throw StateError('gRPC call requires a Firebase id token');
      }
      return CallOptions(metadata: {'authorization': 'Bearer $token'});
    },
    loading: () {
      throw StateError('gRPC call started before Firebase id token loaded');
    },
    error: (error, _) {
      throw StateError('Firebase id token failed: $error');
    },
  );
});
