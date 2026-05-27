import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/auth/ensure_anonymous_authentication.dart';
import 'package:frontend/firebase/initialize_firebase.dart';
import 'package:frontend/social_example_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await ensureAnonymousAuthentication(FirebaseAuth.instance);
  runApp(const SocialExampleApp());
}
