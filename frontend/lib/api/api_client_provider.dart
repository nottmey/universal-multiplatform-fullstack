import 'package:client/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/api_base_uri_provider.dart';
import 'package:frontend/auth/authentication_state_provider.dart';

final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final token = await ref.watch(authenticationIdTokenProvider.future);
  if (token == null || token.isEmpty) {
    throw StateError('API call requires a Firebase id token');
  }
  return ApiClient(
    baseUri: ref.watch(apiBaseUriProvider),
    readSecret: (_) => token,
  );
});
