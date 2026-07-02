import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/api/api_offline_retry.dart';
import 'package:frontend/auth/authentication_gate.dart';
import 'package:frontend/features/timeline/timeline_screen.dart';

class SocialExampleApp extends StatelessWidget {
  const SocialExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // Retry transient/offline provider failures (notably the EventBus
      // socket) with jittered backoff; logic errors surface immediately.
      retry: offlineUnboundedRetryDelay,
      child: MaterialApp(
        title: 'Social Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const AuthenticationGate(child: TimelineScreen()),
      ),
    );
  }
}
