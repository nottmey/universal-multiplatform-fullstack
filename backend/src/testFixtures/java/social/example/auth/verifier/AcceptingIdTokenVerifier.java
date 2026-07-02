package social.example.auth.verifier;

import com.google.firebase.auth.FirebaseAuthException;

/**
 * Test double for {@link FirebaseIdTokenVerifier}. In-process tests pass the Firebase user id as
 * the bearer token / token query parameter; production uses real ID tokens.
 */
public final class AcceptingIdTokenVerifier implements FirebaseIdTokenVerifier {
  @Override
  public String verifyUserId(final String idToken) throws FirebaseAuthException {
    return idToken;
  }
}
