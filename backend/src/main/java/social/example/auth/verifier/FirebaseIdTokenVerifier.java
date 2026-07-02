package social.example.auth.verifier;

import com.google.firebase.auth.FirebaseAuthException;

public interface FirebaseIdTokenVerifier {
  /** Verifies the id token and returns the authenticated Firebase user id. */
  String verifyUserId(String idToken) throws FirebaseAuthException;
}
