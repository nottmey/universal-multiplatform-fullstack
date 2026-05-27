import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/auth/authentication_repository.dart';

Future<void> signOut(WidgetRef ref) {
  return ref.read(authenticationRepositoryProvider).signOut();
}
