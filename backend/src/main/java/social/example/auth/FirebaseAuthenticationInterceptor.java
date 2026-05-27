package social.example.auth;

import com.google.firebase.auth.FirebaseAuthException;
import io.grpc.Contexts;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.ServerInterceptor;
import io.grpc.Status;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.auth.verifier.FirebaseIdTokenVerifier;

@Log4j2
@RequiredArgsConstructor
public final class FirebaseAuthenticationInterceptor implements ServerInterceptor {
  private static final Metadata.Key<String> AUTHORIZATION_METADATA_KEY =
      Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER);
  private static final String BEARER_PREFIX = "Bearer ";

  private final FirebaseIdTokenVerifier verifier;

  @Override
  public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
      final ServerCall<ReqT, RespT> call,
      final Metadata headers,
      final ServerCallHandler<ReqT, RespT> next) {
    val authorizationHeader = headers.get(AUTHORIZATION_METADATA_KEY);
    if (authorizationHeader == null || authorizationHeader.isBlank()) {
      call.close(
          Status.UNAUTHENTICATED.withDescription("missing authorization bearer token"), headers);
      return new ServerCall.Listener<>() {};
    }
    if (!authorizationHeader.regionMatches(true, 0, BEARER_PREFIX, 0, BEARER_PREFIX.length())) {
      call.close(
          Status.UNAUTHENTICATED.withDescription("authorization must use Bearer scheme"), headers);
      return new ServerCall.Listener<>() {};
    }
    val idToken = authorizationHeader.substring(BEARER_PREFIX.length()).trim();
    if (idToken.isEmpty()) {
      call.close(Status.UNAUTHENTICATED.withDescription("empty bearer token"), headers);
      return new ServerCall.Listener<>() {};
    }
    try {
      val firebaseToken = verifier.verify(idToken);
      log.info("authenticated firebase {}", firebaseToken);
      val authenticatedContext = FirebaseUserContext.attachToContext(firebaseToken);
      return Contexts.interceptCall(authenticatedContext, call, headers, next);
    } catch (final FirebaseAuthException firebaseAuthException) {
      log.debug("firebase token verification failed", firebaseAuthException);
      call.close(Status.UNAUTHENTICATED.withDescription("invalid firebase id token"), headers);
      return new ServerCall.Listener<>() {};
    }
  }
}
