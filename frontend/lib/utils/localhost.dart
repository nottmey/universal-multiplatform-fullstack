import 'package:flutter/foundation.dart';

/// Loopback host for local backend and emulators on the respective platform.
String get localhost {
  if (kIsWeb) {
    return '127.0.0.1';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return '127.0.0.1';
}
