package social.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.http.HttpResponse;
import java.util.concurrent.TimeUnit;
import java.util.function.BooleanSupplier;
import java.util.function.Supplier;
import lombok.val;
import social.example.api.ApiError;

public final class HttpTestSupport {
  public static final String TEST_USER_ID = "test-user";
  public static final ObjectMapper JSON = new ObjectMapper();

  private static final long AWAIT_TIMEOUT_MILLIS = 2000L;
  private static final long POLL_INTERVAL_MILLIS = 5L;

  private HttpTestSupport() {}

  public static void assertApiError(
      final HttpResponse<String> response,
      final int status,
      final String code,
      final String message) {
    assertEquals(status, response.statusCode(), response::body);
    final ApiError error;
    try {
      error = JSON.readValue(response.body(), ApiError.class);
    } catch (final Exception e) {
      throw new AssertionError("unparseable ApiError body: " + response.body(), e);
    }
    assertEquals(code, error.code(), response::body);
    assertEquals(message, error.message(), response::body);
  }

  public static void assertInvalidArgument(
      final HttpResponse<String> response, final String message) {
    assertApiError(response, 400, "INVALID_ARGUMENT", message);
  }

  public static void assertNotFound(final HttpResponse<String> response) {
    assertApiError(response, 404, "NOT_FOUND", "post not found");
  }

  public static void awaitTrue(final BooleanSupplier condition, final String description)
      throws InterruptedException {
    awaitTrue(condition, () -> description);
  }

  public static void awaitTrue(final BooleanSupplier condition, final Supplier<String> description)
      throws InterruptedException {
    val deadlineNanos = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(AWAIT_TIMEOUT_MILLIS);
    while (System.nanoTime() < deadlineNanos) {
      if (condition.getAsBoolean()) {
        return;
      }
      Thread.sleep(POLL_INTERVAL_MILLIS);
    }
    throw new AssertionError(description.get());
  }
}
