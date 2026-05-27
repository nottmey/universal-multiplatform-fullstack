package social.example.auth;

import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import io.grpc.ServerInterceptor;
import java.io.IOException;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.auth.verifier.DefaultFirebaseIdTokenVerifier;

@Log4j2
public final class FirebaseBootstrap {
  // see https://firebase.google.com/docs/emulator-suite/connect_auth#admin_sdks
  public static final String AUTH_EMULATOR_HOST_ENV = "FIREBASE_AUTH_EMULATOR_HOST";

  private FirebaseBootstrap() {}

  public static ServerInterceptor interceptor() {
    return new FirebaseAuthenticationInterceptor(new DefaultFirebaseIdTokenVerifier());
  }

  public static void initialize() {
    if (FirebaseApp.getApps().isEmpty()) {
      val authEmulatorHost = System.getenv(AUTH_EMULATOR_HOST_ENV);
      if (authEmulatorHost == null || authEmulatorHost.isBlank()) {
        initializeForProduction();
      } else {
        initializeForDevelopment();
      }
    } else {
      throw new IllegalStateException("firebase is already initialized");
    }
  }

  private static void initializeForProduction() {
    final GoogleCredentials credentials;
    try {
      credentials = GoogleCredentials.getApplicationDefault();
    } catch (final IOException ioException) {
      throw new IllegalStateException(
          "firebase credentials missing; for local dev set " + AUTH_EMULATOR_HOST_ENV, ioException);
    }
    FirebaseApp.initializeApp(FirebaseOptions.builder().setCredentials(credentials).build());
    log.info("firebase initialized for project {}", credentials.getProjectId());
  }

  private static void initializeForDevelopment() {
    FirebaseApp.initializeApp(
        FirebaseOptions.builder()
            .setProjectId("social-example-dev")
            .setCredentials(GoogleCredentials.create(new AccessToken("development", null)))
            .build());
    log.info("firebase development credentials initialized");
  }
}
