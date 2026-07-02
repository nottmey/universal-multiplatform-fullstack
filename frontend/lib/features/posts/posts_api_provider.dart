import 'package:client/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/api_client_provider.dart';

final postsApiProvider = FutureProvider<PostsApi>((ref) async {
  return PostsApi(await ref.watch(apiClientProvider.future));
});
