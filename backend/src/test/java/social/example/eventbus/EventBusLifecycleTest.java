package social.example.eventbus;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static social.example.HttpTestSupport.awaitTrue;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import lombok.val;
import org.junit.jupiter.api.Test;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;

class EventBusLifecycleTest {

  @Test
  void eventBus_emitsConnectionReadyWhenSocketOpens() throws Exception {
    try (val server = new EventBusTestServer();
        val client = server.connectTestUser()) {
      // EventBusTestClient.connect only returns after the connectionReady handshake.
      client.assertBuffersDrained();
    }
  }

  @Test
  void eventBus_deliversSyntheticTimelineEvent_withSubscriptionId() throws Exception {
    val timelineStub =
        new EventBusSubscription() {
          @Override
          public SubscriptionCase subscriptionCase() {
            return SubscriptionCase.TIMELINE;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final SubscribeCommand command) {
            session.emit(
                EventBusServerMessage.timeline(command.subscriptionId(), List.of("stub-post")));
            return () -> {};
          }
        };
    try (val server = new EventBusTestServer(List.of(timelineStub));
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      client.subscribe(SubscribeCommand.timeline(subscriptionId));
      client.awaitEvent(
          event ->
              subscriptionId.equals(event.subscriptionId())
                  && event.timeline() != null
                  && event.timeline().postIds().contains("stub-post"),
          "expected synthetic timeline event for subscription " + subscriptionId);
    }
  }

  @Test
  void subscribe_addsPostSubscription() throws Exception {
    val postStub =
        new EventBusSubscription() {
          @Override
          public SubscriptionCase subscriptionCase() {
            return SubscriptionCase.POST;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final SubscribeCommand command) {
            session.emit(
                EventBusServerMessage.post(
                    command.subscriptionId(),
                    new social.example.api.Post(command.post().postId(), "", 0L)));
            return () -> {};
          }
        };
    try (val server = new EventBusTestServer(List.of(postStub));
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      val postId = "post-for-subscribe";
      client.subscribe(SubscribeCommand.post(subscriptionId, postId));
      client.awaitEvent(
          event ->
              subscriptionId.equals(event.subscriptionId())
                  && event.post() != null
                  && event.post().post() != null
                  && postId.equals(event.post().post().postId()),
          "expected post event for subscription " + subscriptionId);
    }
  }

  @Test
  void subscribe_secondSubscribeWithSameId_closesFirstHandle() throws Exception {
    val firstClosed = new AtomicBoolean(false);
    val secondClosed = new AtomicBoolean(false);
    val subscribeOrdinal = new AtomicInteger(0);
    val postStub = countingPostSubscription(subscribeOrdinal, firstClosed, secondClosed);
    try (val server = new EventBusTestServer(List.of(postStub));
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      val command = SubscribeCommand.post(subscriptionId, "post-double-subscribe");
      client.subscribe(command);
      awaitTrue(() -> subscribeOrdinal.get() == 1, "first subscribe should reach the handler");
      assertFalse(firstClosed.get());
      client.subscribe(command);
      awaitTrue(firstClosed::get, "second subscribe with same id should close the first handle");
      assertFalse(secondClosed.get());
      client.unsubscribe(subscriptionId);
      awaitTrue(secondClosed::get, "unsubscribe should close the second handle");
    }
  }

  @Test
  void unsubscribe_closesPostSubscription() throws Exception {
    val postClosed = new AtomicBoolean(false);
    val subscribed = new AtomicInteger(0);
    val postStub = countingPostSubscription(subscribed, postClosed, new AtomicBoolean());
    try (val server = new EventBusTestServer(List.of(postStub));
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      client.subscribe(SubscribeCommand.post(subscriptionId, "any"));
      awaitTrue(() -> subscribed.get() == 1, "subscribe should reach the handler");
      assertFalse(postClosed.get());
      client.unsubscribe(subscriptionId);
      awaitTrue(postClosed::get, "unsubscribe should close the subscription handle");
    }
  }

  @Test
  void eventBus_closingSocketClosesAllSubscriptionHandles() throws Exception {
    val postClosed = new AtomicBoolean(false);
    val subscribed = new AtomicInteger(0);
    val postStub = countingPostSubscription(subscribed, postClosed, new AtomicBoolean());
    try (val server = new EventBusTestServer(List.of(postStub))) {
      val client = server.connectTestUser();
      client.subscribe(SubscribeCommand.post(UUID.randomUUID().toString(), "any"));
      awaitTrue(() -> subscribed.get() == 1, "subscribe should reach the handler");
      assertFalse(postClosed.get());
      client.close();
      awaitTrue(postClosed::get, "closing the socket should close all subscription handles");
    }
  }

  @Test
  void eventBus_concurrentSocketsHaveIndependentSubscriptionMaps() throws Exception {
    val firstClosed = new AtomicBoolean(false);
    val secondClosed = new AtomicBoolean(false);
    val subscribeOrdinal = new AtomicInteger(0);
    val postStub = countingPostSubscription(subscribeOrdinal, firstClosed, secondClosed);
    try (val server = new EventBusTestServer(List.of(postStub));
        val firstSocket = server.connect("first-user");
        val secondSocket = server.connect("second-user")) {
      val sharedSubscriptionId = "shared-subscription-id";
      firstSocket.subscribe(SubscribeCommand.post(sharedSubscriptionId, "any"));
      awaitTrue(() -> subscribeOrdinal.get() == 1, "first subscribe should reach the handler");
      secondSocket.subscribe(SubscribeCommand.post(sharedSubscriptionId, "any"));
      awaitTrue(() -> subscribeOrdinal.get() == 2, "second subscribe should reach the handler");
      // The same subscription id on another socket must not displace the first socket's handle.
      assertFalse(firstClosed.get());
      assertFalse(secondClosed.get());
    }
  }

  private static EventBusSubscription countingPostSubscription(
      final AtomicInteger subscribeOrdinal,
      final AtomicBoolean firstClosed,
      final AtomicBoolean secondClosed) {
    return new EventBusSubscription() {
      @Override
      public SubscriptionCase subscriptionCase() {
        return SubscriptionCase.POST;
      }

      @Override
      public AutoCloseable subscribe(
          final EventBusSession session, final SubscribeCommand command) {
        val ordinal = subscribeOrdinal.incrementAndGet();
        return () -> {
          if (ordinal == 1) {
            firstClosed.set(true);
          } else {
            secondClosed.set(true);
          }
        };
      }
    };
  }
}
