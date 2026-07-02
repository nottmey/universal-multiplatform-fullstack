package social.example.eventbus;

import io.javalin.Javalin;
import java.util.Arrays;
import java.util.List;
import lombok.val;
import social.example.HttpTestSupport;
import social.example.Main;
import social.example.api.SubscribeCommand;
import social.example.auth.verifier.AcceptingIdTokenVerifier;
import social.example.features.InstalledFeature;

/** Javalin app exposing only the EventBus WebSocket with injected subscription handlers. */
public final class EventBusTestServer implements AutoCloseable {
  private final Javalin app;

  public EventBusTestServer() {
    this(noopSubscriptionsForAllFeatures());
  }

  public EventBusTestServer(final List<EventBusSubscription> subscriptions) {
    app =
        Main.buildApp(
                new AcceptingIdTokenVerifier(),
                List.of(new InstalledFeature(List.of(), subscriptions)))
            .start(0);
  }

  public int port() {
    return app.port();
  }

  public EventBusTestClient connectTestUser() throws InterruptedException {
    return EventBusTestClient.connect(app.port(), HttpTestSupport.TEST_USER_ID);
  }

  public EventBusTestClient connect(final String userId) throws InterruptedException {
    return EventBusTestClient.connect(app.port(), userId);
  }

  public static List<EventBusSubscription> noopSubscriptionsForAllFeatures() {
    return Arrays.stream(SubscriptionCase.values())
        .map(EventBusTestServer::noopSubscription)
        .toList();
  }

  private static EventBusSubscription noopSubscription(final SubscriptionCase subscriptionCase) {
    return new EventBusSubscription() {
      @Override
      public SubscriptionCase subscriptionCase() {
        return subscriptionCase;
      }

      @Override
      public AutoCloseable subscribe(
          final EventBusSession session, final SubscribeCommand command) {
        return () -> {};
      }
    };
  }

  @Override
  public void close() {
    val current = app;
    if (current != null) {
      current.stop();
    }
  }
}
