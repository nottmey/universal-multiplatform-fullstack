import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/posts/post_compose_notifier.dart';
import 'package:frontend/features/posts/post_keyboard.dart';
import 'package:frontend/keys.dart';

class PostComposeBar extends ConsumerWidget {
  const PostComposeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(timelineComposeBodyControllerProvider);
    final submission = ref.watch(postComposeSubmissionProvider);
    final disabled = submission.posting;

    KeyEventResult onComposeKey(node, event) {
      return postComposeEnterSubmit(
        event,
        () => unawaited(
          ref.read(postComposeSubmissionProvider.notifier).submit(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: onComposeKey,
              child: TextField(
                key: Keys.timelineComposeBody,
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'New post',
                  border: const OutlineInputBorder(),
                  errorText: submission.submitError,
                ),
                onChanged: (_) {
                  if (submission.submitError != null) {
                    ref
                        .read(postComposeSubmissionProvider.notifier)
                        .clearSubmitError();
                  }
                },
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                enabled: !disabled,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: Keys.timelineComposeSubmit,
            onPressed: disabled
                ? null
                : () => unawaited(
                    ref.read(postComposeSubmissionProvider.notifier).submit(),
                  ),
            child: submission.posting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }
}
