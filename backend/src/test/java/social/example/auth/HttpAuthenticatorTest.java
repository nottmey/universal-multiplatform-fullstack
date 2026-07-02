package social.example.auth;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static social.example.HttpTestSupport.assertApiError;

import io.javalin.Javalin;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CompletionException;
import lombok.val;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import social.example.Main;
import social.example.RamaTestStubs;
import social.example.auth.verifier.RejectingIdTokenVerifier;
import social.example.eventbus.EventBusTestClient;
import social.example.features.InstalledFeature;
import social.example.features.posts.PostController;

class HttpAuthenticatorTest {
  private Javalin app;

  @BeforeEach
  void startApp() {
    val postController =
        new PostController(RamaTestStubs.throwingDepot(), RamaTestStubs.emptyPState());
    app =
        Main.buildApp(
                new RejectingIdTokenVerifier(),
                List.of(
                    new InstalledFeature(
                        List.<java.util.function.Consumer<Javalin>>of(
                            postController::registerRoutes),
                        List.of())))
            .start(0);
  }

  @AfterEach
  void stopApp() {
    if (app != null) {
      app.stop();
      app = null;
    }
  }

  @Test
  void rejectsMissingAuthorizationHeader() throws Exception {
    val response = createPost(null);
    assertApiError(response, 401, "UNAUTHENTICATED", "missing authorization bearer token");
  }

  @Test
  void rejectsNonBearerScheme() throws Exception {
    val response = createPost("Basic dXNlcjpwYXNz");
    assertApiError(response, 401, "UNAUTHENTICATED", "authorization must use Bearer scheme");
  }

  @Test
  void rejectsEmptyBearerToken() throws Exception {
    val response = createPost("Bearer");
    assertApiError(response, 401, "UNAUTHENTICATED", "empty bearer token");
  }

  @Test
  void rejectsInvalidBearerToken() throws Exception {
    val response = createPost("Bearer not-a-valid-token");
    assertApiError(response, 401, "UNAUTHENTICATED", "invalid firebase id token");
  }

  @Test
  void wsUpgrade_rejectsMissingTokenQueryParam() {
    assertThrows(
        CompletionException.class,
        () -> EventBusTestClient.tryConnect(app.port(), null, new WebSocket.Listener() {}).join());
  }

  @Test
  void wsUpgrade_rejectsInvalidToken() {
    assertThrows(
        CompletionException.class,
        () ->
            EventBusTestClient.tryConnect(app.port(), "invalid", new WebSocket.Listener() {})
                .join());
  }

  private HttpResponse<String> createPost(final String authorizationHeader) throws Exception {
    val requestBuilder =
        HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + app.port() + "/posts"))
            .timeout(Duration.ofSeconds(5))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString("{\"body\":\"blocked\"}"));
    if (authorizationHeader != null) {
      requestBuilder.header("Authorization", authorizationHeader);
    }
    return HttpClient.newHttpClient()
        .send(requestBuilder.build(), HttpResponse.BodyHandlers.ofString());
  }
}
