import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/auth/authentication_repository.dart';

final authenticationUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authenticationRepositoryProvider).authStateChanges();
});

final authenticationIdTokenProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(authenticationUserProvider.future);
  if (user == null || user.isAnonymous) {
    return null;
  }
  return user.getIdToken(true);
});
