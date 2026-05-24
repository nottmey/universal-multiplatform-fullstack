import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Plain Enter submits; Shift+Enter still inserts newline.
KeyEventResult postComposeEnterSubmit(KeyEvent event, VoidCallback submit) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;
  if (event.logicalKey != LogicalKeyboardKey.enter) {
    return KeyEventResult.ignored;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    return KeyEventResult.ignored;
  }
  submit();
  return KeyEventResult.handled;
}
