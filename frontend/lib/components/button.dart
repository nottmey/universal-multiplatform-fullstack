import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  const Button._({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final Future<void> Function() onPressed;
  final Widget icon;

  factory Button.icon({
    Key? key,
    required String tooltip,
    required Future<void> Function() onPressed,
    required Widget icon,
  }) => Button._(key: key, tooltip: tooltip, onPressed: onPressed, icon: icon);

  @override
  State<Button> createState() => _ButtonState();
}

final class _ButtonState extends State<Button> {
  var _isBusy = false;

  Future<void> _handlePressed() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _isBusy ? null : () => _handlePressed(),
      icon: widget.icon,
    );
  }
}
