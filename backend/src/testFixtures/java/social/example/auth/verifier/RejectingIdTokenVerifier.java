package social.example.auth.verifier;

import com.google.firebase.ErrorCode;
import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuthException;

public final class RejectingIdTokenVerifier implements FirebaseIdTokenVerifier {
  @Override
  public String verifyUserId(final String idToken) throws FirebaseAuthException {
    throw new FirebaseAuthException(
        ErrorCode.INVALID_ARGUMENT,
        "invalid firebase id token",
        null,
        null,
        AuthErrorCode.INVALID_ID_TOKEN);
  }
}
