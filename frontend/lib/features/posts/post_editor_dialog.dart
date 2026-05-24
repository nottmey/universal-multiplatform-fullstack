import 'dart:async';

import 'package:flutter/material.dart';

import 'package:frontend/proto/posts.pb.dart';
import 'package:frontend/keys.dart';

import 'post_editor_result.dart';
import 'post_keyboard.dart';

class PostEditorDialog extends StatefulWidget {
  const PostEditorDialog({super.key, required this.post});

  final Post post;

  @override
  State<PostEditorDialog> createState() => _PostEditorDialogState();
}

class _PostEditorDialogState extends State<PostEditorDialog> {
  late final TextEditingController _controller;
  late final FocusNode _fieldFocus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.post.body);
    _fieldFocus = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This removes the post from the timeline.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: Keys.timelineDeleteConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const PostEditorResult(deleted: true));
    }
  }

  void _save() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop(PostEditorResult(savedBody: trimmed));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit post', key: Keys.timelinePostEditorTitle),
      content: Focus(
        onKeyEvent: (node, event) => postComposeEnterSubmit(event, _save),
        child: TextField(
          controller: _controller,
          focusNode: _fieldFocus,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(
          key: Keys.timelineEditDelete,
          onPressed: () => unawaited(_confirmDelete()),
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: Keys.timelinePostEditorSave,
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
