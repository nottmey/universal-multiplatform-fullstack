import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/firebase/firebase_options.dart';
import 'package:frontend/utils/localhost.dart';

const int _authEmulatorPort = int.fromEnvironment(
  'AUTH_EMULATOR_PORT',
  defaultValue: 0,
);

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_authEmulatorPort > 0) {
    await FirebaseAuth.instance.useAuthEmulator(localhost, _authEmulatorPort);
  }
}
