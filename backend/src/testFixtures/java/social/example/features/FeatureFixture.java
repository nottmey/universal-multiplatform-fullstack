package social.example.features;

import com.rpl.rama.test.InProcessCluster;
import io.javalin.Javalin;
import java.util.Arrays;
import java.util.List;
import java.util.function.Predicate;
import lombok.val;
import org.junit.jupiter.api.extension.AfterEachCallback;
import org.junit.jupiter.api.extension.BeforeEachCallback;
import org.junit.jupiter.api.extension.ExtensionContext;
import social.example.ApiTestClient;
import social.example.HttpTestSupport;
import social.example.Main;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;
import social.example.auth.verifier.AcceptingIdTokenVerifier;
import social.example.eventbus.EventBusTestClient;

// assume fixture is only used in tests and always mounted correctly
public class FeatureFixture implements BeforeEachCallback, AfterEachCallback {
  private final InstallableFeature[] installableFeatures;
  private InProcessCluster cluster;
  private Javalin app;
  private ApiTestClient api;
  private EventBusTestClient eventBus;

  public FeatureFixture(final InstallableFeature... installableFeatures) {
    this.installableFeatures = installableFeatures;
  }

  public InProcessCluster cluster() {
    return cluster;
  }

  public ApiTestClient api() {
    return api;
  }

  public EventBusTestClient eventBus() {
    return eventBus;
  }

  public List<EventBusServerMessage> drainEventBusEvents() {
    return eventBus.drainEvents();
  }

  public List<EventBusServerMessage> awaitAndDrainEventBusEvents(final int count)
      throws InterruptedException {
    return eventBus.awaitAndDrainEvents(count);
  }

  public List<Throwable> drainEventBusStreamErrors() {
    return eventBus.drainErrors();
  }

  public void awaitEventBusEvent(
      final Predicate<EventBusServerMessage> predicate, final String description)
      throws InterruptedException {
    eventBus.awaitEvent(predicate, description);
  }

  public void assertNoEventBusEventsWithin(final long millis) throws InterruptedException {
    eventBus.assertNoEventsWithin(millis);
  }

  public void subscribe(final SubscribeCommand command) {
    eventBus.subscribe(command);
  }

  public void unsubscribe(final String subscriptionId) {
    eventBus.unsubscribe(subscriptionId);
  }

  @Override
  public void beforeEach(final ExtensionContext extensionContext) throws Exception {
    cluster = InProcessCluster.create();
    val installedFeatures =
        Arrays.stream(installableFeatures)
            .map(installableFeature -> installableFeature.installOn(cluster))
            .toList();
    app = Main.buildApp(new AcceptingIdTokenVerifier(), installedFeatures).start(0);
    api = new ApiTestClient(app.port(), HttpTestSupport.TEST_USER_ID);
    eventBus = EventBusTestClient.connect(app.port(), HttpTestSupport.TEST_USER_ID);
  }

  @Override
  public void afterEach(final ExtensionContext extensionContext) throws Exception {
    try {
      if (eventBus != null) {
        eventBus.assertBuffersDrained();
      }
    } finally {
      if (eventBus != null) {
        eventBus.close();
        eventBus = null;
      }
      if (app != null) {
        app.stop();
        app = null;
      }
      if (cluster != null) {
        cluster.close();
        cluster = null;
      }
      api = null;
    }
  }
}
