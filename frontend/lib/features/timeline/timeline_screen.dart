import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/posts/post_compose_bar.dart';
import 'package:frontend/features/posts/post_timeline_tile.dart';
import 'package:frontend/features/timeline/timeline_feed_notifier.dart';
import 'package:frontend/grpc/grpc_connection_epoch_provider.dart';
import 'package:frontend/keys.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(timelineFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            key: Keys.timelineAppBarRefresh,
            onPressed: feed.subscriptionErrorMessage != null || feed.feedReady
                ? ref.onForceRefresh
                : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PostComposeBar(),
          const Divider(height: 1),
          Expanded(
            child: feed.subscriptionErrorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            feed.subscriptionErrorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          TextButton(
                            onPressed: ref.onForceRefresh,
                            child: const Text('Reload'),
                          ),
                        ],
                      ),
                    ),
                  )
                : !feed.feedReady
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    key: Keys.timelineRefreshIndicator,
                    onRefresh: ref.onForceRefresh,
                    child: feed.postIds.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'No posts yet',
                                  key: Keys.timelineEmptyFeed,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: feed.postIds.length,
                            itemBuilder: (context, index) {
                              final postId = feed.postIds[index];
                              return PostTimelineTile(
                                key: ValueKey(postId),
                                postId: postId,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
