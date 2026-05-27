package social.example.auth.verifier;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;

public interface FirebaseIdTokenVerifier {
  FirebaseToken verify(String idToken) throws FirebaseAuthException;
}
