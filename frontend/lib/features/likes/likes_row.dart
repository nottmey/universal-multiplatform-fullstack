import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/components/button.dart';
import 'package:frontend/event_bus/event_subscriptions_provider.dart';
import 'package:frontend/features/likes/likes_service_client_provider.dart';
import 'package:frontend/grpc/grpc_connection_epoch_provider.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/likes.pbgrpc.dart';
import 'package:frontend/keys.dart';

class LikesRow extends ConsumerWidget {
  const LikesRow({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(
      eventSubscriptionsProvider(
        Subscription(likes: SubscribeLikesRequest(postId: postId)),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        ...subscription.when(
          loading: () => [CircularProgressIndicator()],
          error: (e, s) => [
            Button.icon(
              tooltip: 'Reload (${e.toString()})',
              onPressed: ref.onForceRefresh,
              icon: Icon(Icons.error),
            ),
          ],
          data: (event) => [
            Text(event.likes.likeCount.toString()),
            Button.icon(
              key: Keys.timelinePostLike,
              tooltip: 'Like',
              onPressed: () async {
                final likesServiceClient = await ref.read(
                  likesServiceClientProvider.future,
                );
                await likesServiceClient.like(LikeRequest(postId: postId));
              },
              icon: const Icon(Icons.favorite_outline),
            ),
          ],
        ),
      ],
    );
  }
}
