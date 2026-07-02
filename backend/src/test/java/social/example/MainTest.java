package social.example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static social.example.HttpTestSupport.assertApiError;

import com.google.firebase.FirebaseApp;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import lombok.val;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import social.example.auth.FirebaseAuthEmulatorClient;

class MainTest {
  private static final HttpClient HTTP_CLIENT =
      HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

  @AfterEach
  void deleteFirebaseApps() {
    FirebaseApp.getApps().forEach(FirebaseApp::delete);
  }

  @Test
  void bootstrap_devScenarioSmoke() throws Exception {
    try (val application = Main.bootstrap(new String[] {"0"})) {
      application.app.start(application.port);
      val serverUri = "http://127.0.0.1:" + application.app.port();

      val corsResponse =
          HTTP_CLIENT.send(
              HttpRequest.newBuilder(URI.create(serverUri + "/posts"))
                  .method("OPTIONS", HttpRequest.BodyPublishers.noBody())
                  .header("Origin", "http://localhost:3000")
                  .header("Access-Control-Request-Method", "POST")
                  .build(),
              HttpResponse.BodyHandlers.ofString());
      assertEquals(
          "*", corsResponse.headers().firstValue("Access-Control-Allow-Origin").orElse(null));

      val unauthenticated =
          HTTP_CLIENT.send(
              HttpRequest.newBuilder(URI.create(serverUri + "/posts"))
                  .header("Content-Type", "application/json")
                  .POST(HttpRequest.BodyPublishers.ofString("{\"body\":\"blocked\"}"))
                  .build(),
              HttpResponse.BodyHandlers.ofString());
      assertApiError(unauthenticated, 401, "UNAUTHENTICATED", "missing authorization bearer token");

      val openApiResponse =
          HTTP_CLIENT.send(
              HttpRequest.newBuilder(URI.create(serverUri + "/openapi")).GET().build(),
              HttpResponse.BodyHandlers.ofString());
      assertEquals(200, openApiResponse.statusCode());
      assertTrue(openApiResponse.body().contains("/posts"));

      val idToken =
          FirebaseAuthEmulatorClient.signUpEmailPassword(
              FirebaseAuthEmulatorClient.uniqueEmail(), "password-123456");
      val api = new ApiTestClient(application.app.port(), idToken);
      val post = api.createPost("smoke");
      assertFalse(post.postId().isBlank());
      assertEquals("smoke", post.body());
    }
  }
}
