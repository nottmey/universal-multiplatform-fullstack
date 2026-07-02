package social.example.auth.verifier;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;

public final class DefaultFirebaseIdTokenVerifier implements FirebaseIdTokenVerifier {
  @Override
  public String verifyUserId(final String idToken) throws FirebaseAuthException {
    return FirebaseAuth.getInstance().verifyIdToken(idToken).getUid();
  }
}
