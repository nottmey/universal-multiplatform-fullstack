package social.example.eventbus;

import static social.example.GrpcTestSupport.shutdown;

import io.grpc.ManagedChannel;
import io.grpc.Server;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import lombok.val;
import social.example.GrpcTestSupport;
import social.example.auth.FirebaseAuthenticationInterceptor;
import social.example.auth.verifier.AcceptingIdTokenVerifier;
import social.example.eventbus.grpc.ConnectionContext;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.EventBusRequest;
import social.example.eventbus.grpc.EventBusServiceGrpc;
import social.example.eventbus.grpc.SubscribeRequest;
import social.example.eventbus.grpc.Subscription;
import social.example.eventbus.grpc.UnsubscribeRequest;

public class InProcessEventBus implements AutoCloseable {
  private final Server server;
  private final ManagedChannel channel;

  public InProcessEventBus() throws IOException {
    this(noopSubscriptionsForAllFeatures());
  }

  public InProcessEventBus(final List<EventBusSubscription> subscriptions) throws IOException {
    val serverName = InProcessServerBuilder.generateName();
    server =
        InProcessServerBuilder.forName(serverName)
            .directExecutor()
            .addService(EventBusService.fromSubscriptions(subscriptions))
            .intercept(new FirebaseAuthenticationInterceptor(new AcceptingIdTokenVerifier()))
            .build()
            .start();
    channel = InProcessChannelBuilder.forName(serverName).directExecutor().build();
  }

  public static List<EventBusSubscription> noopSubscriptionsForAllFeatures() {
    return Arrays.stream(Subscription.RequestCase.values())
        .filter(requestCase -> requestCase != Subscription.RequestCase.REQUEST_NOT_SET)
        .map(InProcessEventBus::noopSubscription)
        .toList();
  }

  private static EventBusSubscription noopSubscription(
      final Subscription.RequestCase subscriptionCase) {
    return new EventBusSubscription() {
      @Override
      public Subscription.RequestCase subscriptionCase() {
        return subscriptionCase;
      }

      @Override
      public AutoCloseable subscribe(
          final EventBusSession session, final Subscription subscription) {
        return () -> {};
      }
    };
  }

  public void openEventBusWithDiscardedResponses(final ConnectionContext context) {
    asyncStub()
        .eventBus(
            EventBusRequest.newBuilder().setContext(context).build(), discardingEventObserver());
  }

  public void subscribe(final ConnectionContext context, final Subscription subscription) {
    blockingStub()
        .subscribe(
            SubscribeRequest.newBuilder()
                .setContext(context)
                .setSubscription(subscription)
                .build());
  }

  public void unsubscribe(final ConnectionContext context, final String subscriptionId) {
    blockingStub()
        .unsubscribe(
            UnsubscribeRequest.newBuilder()
                .setContext(context)
                .setSubscriptionId(subscriptionId)
                .build());
  }

  public EventBusServiceGrpc.EventBusServiceStub asyncStub() {
    return GrpcTestSupport.withTestUserId(EventBusServiceGrpc.newStub(channel));
  }

  public EventBusServiceGrpc.EventBusServiceBlockingStub blockingStub() {
    return GrpcTestSupport.withTestUserId(EventBusServiceGrpc.newBlockingStub(channel));
  }

  @Override
  public void close() {
    shutdown(channel, server);
  }

  public static StreamObserver<Event> discardingEventObserver() {
    return discardingEventObserver(new AtomicReference<String>());
  }

  public static StreamObserver<Event> discardingEventObserver(
      final AtomicReference<String> errorSink) {
    return new StreamObserver<Event>() {
      @Override
      public void onNext(final Event event) {}

      @Override
      public void onError(final Throwable throwable) {
        errorSink.set(throwable.getMessage());
      }

      @Override
      public void onCompleted() {}
    };
  }
}
