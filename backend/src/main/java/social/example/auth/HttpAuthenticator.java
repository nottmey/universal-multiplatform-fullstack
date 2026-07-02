package social.example.auth;

import com.google.firebase.auth.FirebaseAuthException;
import io.javalin.http.Context;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.api.ApiException;
import social.example.auth.verifier.FirebaseIdTokenVerifier;

@Log4j2
@RequiredArgsConstructor
public final class HttpAuthenticator {
  /** Query parameter carrying the id token on WebSocket upgrades (browsers cannot set headers). */
  public static final String TOKEN_QUERY_PARAM = "token";

  private static final String BEARER_PREFIX = "Bearer ";

  private final FirebaseIdTokenVerifier verifier;

  public void authenticateHttp(final Context ctx) {
    val authorizationHeader = ctx.header("Authorization");
    if (authorizationHeader == null || authorizationHeader.isBlank()) {
      throw ApiException.unauthenticated("missing authorization bearer token");
    }
    // HTTP clients trim trailing whitespace, so "Bearer " arrives as a bare "Bearer".
    if (authorizationHeader.trim().equalsIgnoreCase("Bearer")) {
      throw ApiException.unauthenticated("empty bearer token");
    }
    if (!authorizationHeader.regionMatches(true, 0, BEARER_PREFIX, 0, BEARER_PREFIX.length())) {
      throw ApiException.unauthenticated("authorization must use Bearer scheme");
    }
    val idToken = authorizationHeader.substring(BEARER_PREFIX.length()).trim();
    if (idToken.isEmpty()) {
      throw ApiException.unauthenticated("empty bearer token");
    }
    FirebaseUserContext.attach(ctx, verify(idToken));
  }

  public void authenticateWsUpgrade(final Context ctx) {
    val idToken = ctx.queryParam(TOKEN_QUERY_PARAM);
    if (idToken == null || idToken.isBlank()) {
      throw ApiException.unauthenticated("missing token query parameter");
    }
    FirebaseUserContext.attach(ctx, verify(idToken));
  }

  private String verify(final String idToken) {
    try {
      val userId = verifier.verifyUserId(idToken);
      log.info("authenticated firebase user {}", userId);
      return userId;
    } catch (final FirebaseAuthException firebaseAuthException) {
      log.debug("firebase token verification failed", firebaseAuthException);
      throw ApiException.unauthenticated("invalid firebase id token");
    }
  }
}
