import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/auth/authentication_state_provider.dart';
import 'package:grpc/grpc.dart';

final grpcCallOptionsProvider = Provider<CallOptions>((ref) {
  final idToken = ref.watch(authenticationIdTokenProvider);
  return idToken.when(
    data: (token) {
      if (token == null || token.isEmpty) {
        return CallOptions();
      }
      return CallOptions(metadata: {'authorization': 'Bearer $token'});
    },
    loading: () => CallOptions(),
    error: (_, _) => CallOptions(),
  );
});
