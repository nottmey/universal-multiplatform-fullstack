package social.example.auth;

import com.google.firebase.auth.FirebaseToken;
import io.grpc.Context;
import io.grpc.Status;
import lombok.val;

public final class FirebaseUserContext {
  public static final Context.Key<FirebaseToken> CONTEXT_KEY = Context.key("firebase-token");

  private FirebaseUserContext() {}

  public static Context attachToContext(final FirebaseToken firebaseToken) {
    return Context.current().withValue(CONTEXT_KEY, firebaseToken);
  }

  public static String requireUserId() {
    val firebaseToken = CONTEXT_KEY.get();
    if (firebaseToken == null) {
      throw Status.UNAUTHENTICATED
          .withDescription("missing authenticated firebase user")
          .asRuntimeException();
    }
    val userId = firebaseToken.getUid();
    if (userId.isBlank()) {
      throw Status.UNAUTHENTICATED
          .withDescription("authenticated firebase user id is blank")
          .asRuntimeException();
    }
    return userId;
  }
}
