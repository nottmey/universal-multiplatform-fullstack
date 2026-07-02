package social.example.eventbus;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import social.example.api.EventBusClientMessage;
import social.example.api.SubscribeCommand;

class EventBusInputValidationTest {
  private static final long SETTLE_MILLIS = 200L;

  @Test
  void unsubscribe_unknownSubscriptionId_isIgnored() throws Exception {
    try (val server = new EventBusTestServer();
        val client = server.connectTestUser()) {
      client.unsubscribe(UUID.randomUUID().toString());
      client.assertNoEventsWithin(SETTLE_MILLIS);
    }
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void subscribe_rejectsBlankSubscriptionId(final String subscriptionId) throws Exception {
    try (val server = new EventBusTestServer();
        val client = server.connectTestUser()) {
      client.subscribe(SubscribeCommand.post(subscriptionId, "any"));
      awaitErrorEvent(client, subscriptionId, "INVALID_ARGUMENT", "subscription_id is required");
    }
  }

  @Test
  void subscribe_rejectsMissingSubscriptionOneof() throws Exception {
    try (val server = new EventBusTestServer();
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      client.subscribe(new SubscribeCommand(subscriptionId, null, null));
      awaitErrorEvent(client, subscriptionId, "INVALID_ARGUMENT", "subscription oneof is required");
    }
  }

  @Test
  void subscribe_rejectsUnimplementedSubscriptionCase() throws Exception {
    try (val server = new EventBusTestServer(List.of());
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      client.subscribe(SubscribeCommand.timeline(subscriptionId));
      awaitErrorEvent(
          client, subscriptionId, "UNIMPLEMENTED", "no subscription handler for case: TIMELINE");
    }
  }

  @Test
  void clientMessage_rejectsMissingOneof() throws Exception {
    try (val server = new EventBusTestServer();
        val client = server.connectTestUser()) {
      client.send(new EventBusClientMessage(null, null));
      awaitErrorEvent(client, null, "INVALID_ARGUMENT", "client message oneof is required");
    }
  }

  @Test
  void clientMessage_rejectsUnparseableFrame() throws Exception {
    try (val server = new EventBusTestServer();
        val client = server.connectTestUser()) {
      client.sendRaw("not-json");
      awaitErrorEvent(client, null, "INVALID_ARGUMENT", "unparseable client message");
    }
  }

  private static void awaitErrorEvent(
      final EventBusTestClient client,
      final String subscriptionId,
      final String code,
      final String message)
      throws InterruptedException {
    val events = client.awaitAndDrainEvents(1);
    assertEquals(1, events.size(), () -> "expected a single error event, got: " + events);
    val event = events.getFirst();
    assertEquals(blankToNull(subscriptionId), blankToNull(event.subscriptionId()));
    val error = event.error();
    assertEquals(code, error == null ? null : error.code(), () -> "event: " + event);
    assertEquals(message, error == null ? null : error.message());
  }

  private static String blankToNull(final String value) {
    return value == null || value.isBlank() ? null : value;
  }
}
