package social.example.auth.verifier;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;

/**
 * Test double for {@link FirebaseIdTokenVerifier}. In-process tests pass the Firebase user id via
 * {@link social.example.GrpcTestSupport#withUserId}; production uses real ID tokens.
 */
public final class AcceptingIdTokenVerifier implements FirebaseIdTokenVerifier {
  @Override
  public FirebaseToken verify(final String userId) throws FirebaseAuthException {
    FirebaseToken firebaseToken = mock(FirebaseToken.class);
    when(firebaseToken.getUid()).thenReturn(userId);
    return firebaseToken;
  }
}
