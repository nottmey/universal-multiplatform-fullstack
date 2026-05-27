package social.example.features;

import static social.example.GrpcTestSupport.shutdown;

import com.rpl.rama.test.InProcessCluster;
import io.grpc.ManagedChannel;
import io.grpc.Server;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;
import java.util.function.Predicate;
import lombok.val;
import org.junit.jupiter.api.extension.AfterEachCallback;
import org.junit.jupiter.api.extension.BeforeEachCallback;
import org.junit.jupiter.api.extension.ExtensionContext;
import social.example.GrpcTestSupport;
import social.example.Main;
import social.example.auth.FirebaseAuthenticationInterceptor;
import social.example.auth.verifier.AcceptingIdTokenVerifier;
import social.example.eventbus.grpc.ConnectionContext;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.EventBusRequest;
import social.example.eventbus.grpc.EventBusServiceGrpc;
import social.example.eventbus.grpc.SubscribeRequest;
import social.example.eventbus.grpc.Subscription;
import social.example.eventbus.grpc.UnsubscribeRequest;

// assume fixture is only used in tests and always mounted correctly
public class FeatureFixture implements BeforeEachCallback, AfterEachCallback {
  private final InstallableFeature[] installableFeatures;
  private InProcessCluster cluster;
  private Server server;
  private ManagedChannel channel;
  private ConnectionContext context;
  private EventBusServiceGrpc.EventBusServiceStub eventBusAsyncStub;
  private EventBusServiceGrpc.EventBusServiceBlockingStub eventBusBlockingStub;
  private CopyOnWriteArrayList<Event> eventBusEvents;
  private CopyOnWriteArrayList<Throwable> eventBusStreamErrors;

  @SafeVarargs
  public FeatureFixture(final InstallableFeature... installableFeatures) {
    this.installableFeatures = installableFeatures;
  }

  public <S> S stub(final Function<ManagedChannel, S> stubFactory) {
    return GrpcTestSupport.withTestUserId(stubFactory.apply(channel));
  }

  public InProcessCluster cluster() {
    return cluster;
  }

  public EventBusServiceGrpc.EventBusServiceStub eventBusAsyncStub() {
    return eventBusAsyncStub;
  }

  public EventBusServiceGrpc.EventBusServiceBlockingStub eventBusBlockingStub() {
    return eventBusBlockingStub;
  }

  public List<Event> drainEventBusEvents() {
    val drained = List.copyOf(eventBusEvents);
    eventBusEvents.clear();
    return drained;
  }

  public List<Throwable> drainEventBusStreamErrors() {
    val drained = List.copyOf(eventBusStreamErrors);
    eventBusStreamErrors.clear();
    return drained;
  }

  public void awaitEventBusEvent(final Predicate<Event> predicate, final String description)
      throws InterruptedException {
    val deadlineNanos = System.nanoTime() + TimeUnit.SECONDS.toNanos(2L);
    while (System.nanoTime() < deadlineNanos) {
      for (val event : drainEventBusEvents()) {
        if (predicate.test(event)) {
          return;
        }
      }
      Thread.sleep(5L);
    }
    throw new AssertionError(description);
  }

  public void subscribe(final Subscription subscription) {
    eventBusBlockingStub.subscribe(
        SubscribeRequest.newBuilder().setContext(context).setSubscription(subscription).build());
  }

  public void unsubscribe(final String subscriptionId) {
    eventBusBlockingStub.unsubscribe(
        UnsubscribeRequest.newBuilder()
            .setContext(context)
            .setSubscriptionId(subscriptionId)
            .build());
  }

  @Override
  public void beforeEach(final ExtensionContext extensionContext) throws Exception {
    cluster = InProcessCluster.create();
    val installedFeatures =
        Arrays.stream(installableFeatures)
            .map(installableFeature -> installableFeature.installOn(cluster))
            .toList();
    val serverName = InProcessServerBuilder.generateName();
    val serverBuilder = InProcessServerBuilder.forName(serverName).directExecutor();
    for (val bindable : Main.services(installedFeatures)) {
      serverBuilder.addService(bindable);
    }
    server =
        serverBuilder
            .intercept(new FirebaseAuthenticationInterceptor(new AcceptingIdTokenVerifier()))
            .build();
    channel = InProcessChannelBuilder.forName(serverName).directExecutor().build();
    server.start();

    context = GrpcTestSupport.context("test", 0);
    eventBusAsyncStub = GrpcTestSupport.withTestUserId(EventBusServiceGrpc.newStub(channel));
    eventBusBlockingStub =
        GrpcTestSupport.withTestUserId(EventBusServiceGrpc.newBlockingStub(channel));
    eventBusEvents = new CopyOnWriteArrayList<>();
    eventBusStreamErrors = new CopyOnWriteArrayList<>();

    eventBusAsyncStub.eventBus(
        EventBusRequest.newBuilder().setContext(context).build(),
        new StreamObserver<Event>() {
          @Override
          public void onNext(final Event event) {
            eventBusEvents.add(event);
          }

          @Override
          public void onError(final Throwable throwable) {
            eventBusStreamErrors.add(throwable);
          }

          @Override
          public void onCompleted() {}
        });
  }

  @Override
  public void afterEach(final ExtensionContext extensionContext) throws Exception {
    assertEventBusBuffersDrained();
    if (channel != null || server != null) {
      shutdown(channel, server);
      channel = null;
      server = null;
    }
    if (cluster != null) {
      cluster.close();
      cluster = null;
    }
    context = null;
    eventBusAsyncStub = null;
    eventBusBlockingStub = null;
    eventBusEvents = null;
    eventBusStreamErrors = null;
  }

  private void assertEventBusBuffersDrained() {
    if (eventBusEvents != null && !eventBusEvents.isEmpty()) {
      throw new AssertionError("undrained event bus events: " + List.copyOf(eventBusEvents));
    }
    if (eventBusStreamErrors != null && !eventBusStreamErrors.isEmpty()) {
      throw new AssertionError(
          "undrained event bus stream errors: " + List.copyOf(eventBusStreamErrors));
    }
  }
}
