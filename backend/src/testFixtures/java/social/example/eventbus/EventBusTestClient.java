package social.example.eventbus;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.WebSocket;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.function.Predicate;
import lombok.val;
import social.example.HttpTestSupport;
import social.example.api.EventBusClientMessage;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;

/** WebSocket client for the EventBus; buffers decoded server messages for assertions. */
public final class EventBusTestClient implements AutoCloseable {
  private static final long READY_TIMEOUT_SECONDS = 5L;

  private final WebSocket webSocket;
  private final CopyOnWriteArrayList<EventBusServerMessage> events;
  private final CopyOnWriteArrayList<Throwable> errors;

  private EventBusTestClient(
      final WebSocket webSocket,
      final CopyOnWriteArrayList<EventBusServerMessage> events,
      final CopyOnWriteArrayList<Throwable> errors) {
    this.webSocket = webSocket;
    this.events = events;
    this.errors = errors;
  }

  public static EventBusTestClient connect(final int port, final String userId)
      throws InterruptedException {
    val events = new CopyOnWriteArrayList<EventBusServerMessage>();
    val errors = new CopyOnWriteArrayList<Throwable>();
    val ready = new CountDownLatch(1);
    val webSocket = tryConnect(port, userId, new BufferingListener(events, errors, ready)).join();
    if (!ready.await(READY_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
      throw new AssertionError("event bus did not emit connectionReady; errors: " + errors);
    }
    return new EventBusTestClient(webSocket, events, errors);
  }

  public static CompletableFuture<WebSocket> tryConnect(
      final int port, final String userId, final WebSocket.Listener listener) {
    val query = userId == null ? "" : "?token=" + userId;
    return HttpClient.newHttpClient()
        .newWebSocketBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .buildAsync(URI.create("ws://127.0.0.1:" + port + "/events" + query), listener);
  }

  public void subscribe(final SubscribeCommand command) {
    send(EventBusClientMessage.subscribe(command));
  }

  public void unsubscribe(final String subscriptionId) {
    send(EventBusClientMessage.unsubscribe(subscriptionId));
  }

  public void send(final EventBusClientMessage message) {
    try {
      sendRaw(HttpTestSupport.JSON.writeValueAsString(message));
    } catch (final Exception e) {
      throw new AssertionError("failed to encode client message", e);
    }
  }

  public void sendRaw(final String frame) {
    webSocket.sendText(frame, true).join();
  }

  public List<EventBusServerMessage> drainEvents() {
    val drained = List.copyOf(events);
    events.clear();
    return drained;
  }

  public List<Throwable> drainErrors() {
    val drained = List.copyOf(errors);
    errors.clear();
    return drained;
  }

  /** Waits until at least {@code count} events are buffered, then drains them. */
  public List<EventBusServerMessage> awaitAndDrainEvents(final int count)
      throws InterruptedException {
    HttpTestSupport.awaitTrue(
        () -> events.size() >= count,
        () -> "expected " + count + " event bus events, buffered: " + List.copyOf(events));
    return drainEvents();
  }

  public void awaitEvent(final Predicate<EventBusServerMessage> predicate, final String description)
      throws InterruptedException {
    val deadlineNanos = System.nanoTime() + TimeUnit.SECONDS.toNanos(2L);
    while (System.nanoTime() < deadlineNanos) {
      for (val event : drainEvents()) {
        if (predicate.test(event)) {
          return;
        }
      }
      Thread.sleep(5L);
    }
    throw new AssertionError(description);
  }

  /** Asserts that no event arrives within the given settle window. */
  public void assertNoEventsWithin(final long millis) throws InterruptedException {
    Thread.sleep(millis);
    val arrived = drainEvents();
    if (!arrived.isEmpty()) {
      throw new AssertionError("unexpected event bus events: " + arrived);
    }
  }

  public void assertBuffersDrained() {
    if (!events.isEmpty()) {
      throw new AssertionError("undrained event bus events: " + List.copyOf(events));
    }
    if (!errors.isEmpty()) {
      throw new AssertionError("undrained event bus errors: " + List.copyOf(errors));
    }
  }

  @Override
  public void close() {
    try {
      webSocket.sendClose(WebSocket.NORMAL_CLOSURE, "").join();
    } catch (final Exception e) {
      webSocket.abort();
    }
  }

  private record BufferingListener(
      CopyOnWriteArrayList<EventBusServerMessage> events,
      CopyOnWriteArrayList<Throwable> errors,
      CountDownLatch ready)
      implements WebSocket.Listener {
    @Override
    public CompletionStage<?> onText(
        final WebSocket webSocket, final CharSequence data, final boolean last) {
      // Javalin sends whole text frames; java.net.http delivers them unfragmented for our sizes.
      try {
        val event = HttpTestSupport.JSON.readValue(data.toString(), EventBusServerMessage.class);
        if (event.connectionReady() != null) {
          ready.countDown();
        } else {
          events.add(event);
        }
      } catch (final Exception e) {
        errors.add(e);
      }
      webSocket.request(1);
      return null;
    }

    @Override
    public void onError(final WebSocket webSocket, final Throwable error) {
      errors.add(error);
    }
  }
}
