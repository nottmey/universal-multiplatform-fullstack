import 'package:firebase_auth/firebase_auth.dart';

Future<void> ensureAnonymousAuthentication(FirebaseAuth firebaseAuth) async {
  if (firebaseAuth.currentUser != null) {
    return;
  }
  await firebaseAuth.signInAnonymously();
}
