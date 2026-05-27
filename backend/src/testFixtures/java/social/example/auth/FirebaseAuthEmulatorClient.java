package social.example.auth;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.UUID;

public final class FirebaseAuthEmulatorClient {
  private static final String FAKE_API_KEY = "fake-api-key";
  private static final HttpClient HTTP_CLIENT =
      HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

  private FirebaseAuthEmulatorClient() {}

  public static String signUpEmailPassword(final String email, final String password) {
    String requestBody =
        "{\"email\":\""
            + escapeJson(email)
            + "\",\"password\":\""
            + escapeJson(password)
            + "\",\"returnSecureToken\":true}";
    String response = postIdentityToolkit("accounts:signUp", requestBody);
    return readIdToken(response);
  }

  public static String uniqueEmail() {
    return "patrol-" + UUID.randomUUID() + "@example.com";
  }

  private static String authEmulatorHost() {
    final String host = System.getenv(FirebaseBootstrap.AUTH_EMULATOR_HOST_ENV);
    if (host == null || host.isBlank()) {
      throw new IllegalStateException(
          "missing "
              + FirebaseBootstrap.AUTH_EMULATOR_HOST_ENV
              + "; set it for tests and local dev");
    }
    return host;
  }

  private static String escapeJson(final String value) {
    return value.replace("\\", "\\\\").replace("\"", "\\\"");
  }

  private static String postIdentityToolkit(final String method, final String jsonBody) {
    try {
      URI uri =
          URI.create(
              "http://"
                  + authEmulatorHost()
                  + "/identitytoolkit.googleapis.com/v1/"
                  + method
                  + "?key="
                  + URLEncoder.encode(FAKE_API_KEY, StandardCharsets.UTF_8));
      HttpRequest request =
          HttpRequest.newBuilder(uri)
              .timeout(Duration.ofSeconds(15))
              .header("Content-Type", "application/json")
              .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
              .build();
      HttpResponse<String> response =
          HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
      if (response.statusCode() < 200 || response.statusCode() >= 300) {
        throw new IllegalStateException(
            "identity toolkit "
                + method
                + " failed with status "
                + response.statusCode()
                + ": "
                + response.body());
      }
      return response.body();
    } catch (final InterruptedException interruptedException) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException("interrupted calling auth emulator", interruptedException);
    } catch (final Exception exception) {
      throw new IllegalStateException("failed calling auth emulator", exception);
    }
  }

  private static String readIdToken(final String responseBody) {
    String marker = "\"idToken\":\"";
    int start = responseBody.indexOf(marker);
    if (start < 0) {
      throw new IllegalStateException("response missing idToken: " + responseBody);
    }
    start += marker.length();
    int end = responseBody.indexOf('"', start);
    if (end < 0) {
      throw new IllegalStateException("response missing idToken terminator: " + responseBody);
    }
    return responseBody.substring(start, end);
  }
}
