import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/auth/authentication_screen.dart';
import 'package:frontend/auth/authentication_state_provider.dart';

class AuthenticationGate extends ConsumerWidget {
  const AuthenticationGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticationUser = ref.watch(authenticationUserProvider);
    return authenticationUser.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Authentication error: $error'))),
      data: (user) {
        if (user == null || user.isAnonymous) {
          return const AuthenticationScreen();
        }
        final idToken = ref.watch(authenticationIdTokenProvider);
        return idToken.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => Scaffold(
            body: Center(child: Text('Authentication error: $error')),
          ),
          data: (token) {
            if (token == null || token.isEmpty) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return child;
          },
        );
      },
    );
  }
}
