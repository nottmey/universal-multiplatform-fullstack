package social.example.auth;

import io.javalin.http.Context;
import io.javalin.websocket.WsContext;
import social.example.api.ApiException;

public final class FirebaseUserContext {
  private static final String ATTRIBUTE_KEY = "firebase-user-id";

  private FirebaseUserContext() {}

  public static void attach(final Context ctx, final String userId) {
    ctx.attribute(ATTRIBUTE_KEY, userId);
  }

  public static String requireUserId(final Context ctx) {
    return requireUserId((String) ctx.attribute(ATTRIBUTE_KEY));
  }

  public static String requireUserId(final WsContext ctx) {
    return requireUserId((String) ctx.attribute(ATTRIBUTE_KEY));
  }

  private static String requireUserId(final String userId) {
    if (userId == null) {
      throw ApiException.unauthenticated("missing authenticated firebase user");
    }
    if (userId.isBlank()) {
      throw ApiException.unauthenticated("authenticated firebase user id is blank");
    }
    return userId;
  }
}
