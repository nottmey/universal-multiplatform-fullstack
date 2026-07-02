import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/event_bus/event_bus_force_refresh.dart';
import 'package:frontend/features/posts/post_tile_notifier.dart';
import 'package:frontend/keys.dart';

class PostTimelineTile extends ConsumerWidget {
  const PostTimelineTile({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(postTileProvider(postId), (previous, next) {
      if (next.subscriptionErrorMessage != null) {
        return;
      }
      final message = next.transientErrorMessage;
      if (message == null) {
        return;
      }
      if (previous?.transientErrorMessage == message) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        ref.read(postTileProvider(postId).notifier).clearTransientError();
      });
    });

    final tile = ref.watch(postTileProvider(postId));

    if (tile.isAwaitingDeletion) {
      return const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Removing…'),
        enabled: false,
      );
    }
    final subscriptionErrorMessage = tile.subscriptionErrorMessage;
    if (subscriptionErrorMessage != null) {
      return ListTile(
        title: Text(
          subscriptionErrorMessage,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        subtitle: TextButton(
          onPressed: ref.onForceRefresh,
          child: const Text('Reload'),
        ),
      );
    }
    final post = tile.post;
    if (tile.isLoadingPostPayload && post == null) {
      return const ListTile(
        key: Keys.timelinePostPayloadLoading,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading…'),
      );
    }
    if (post == null) {
      return const SizedBox.shrink();
    }
    return ListTile(
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tile.isPostMutationInFlight || tile.isAwaitingDeletion
            ? null
            : () => unawaited(
                ref.read(postTileProvider(postId).notifier).openEditor(context),
              ),
        child: Text(post.body),
      ),
      subtitle: Text(
        'id=${post.postId} · ${_formatPostTimestampMillis(post.postedAtMillis)}',
      ),
    );
  }
}

String _formatPostTimestampMillis(int millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == 0) {
    return '—';
  }
  return DateTime.fromMillisecondsSinceEpoch(
    millisecondsSinceEpoch,
    isUtc: true,
  ).toLocal().toIso8601String();
}
