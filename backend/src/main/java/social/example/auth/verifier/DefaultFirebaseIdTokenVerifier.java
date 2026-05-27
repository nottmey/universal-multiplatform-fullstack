package social.example.auth.verifier;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;

public final class DefaultFirebaseIdTokenVerifier implements FirebaseIdTokenVerifier {
  @Override
  public FirebaseToken verify(final String idToken) throws FirebaseAuthException {
    return FirebaseAuth.getInstance().verifyIdToken(idToken);
  }
}
