package social.example.eventbus;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static social.example.GrpcTestSupport.context;

import io.grpc.Context;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.StreamObserver;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import lombok.val;
import org.junit.jupiter.api.Test;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.EventBusRequest;
import social.example.eventbus.grpc.SubscribeRequest;
import social.example.eventbus.grpc.Subscription;
import social.example.eventbus.grpc.UnsubscribeRequest;
import social.example.features.likes.grpc.SubscribeLikesRequest;
import social.example.features.likes.grpc.SubscribeLikesResponse;
import social.example.features.timeline.grpc.SubscribeTimelineRequest;
import social.example.features.timeline.grpc.SubscribeTimelineResponse;

class EventBusLifecycleTest {
  private static final long STREAM_TIMEOUT_SECONDS = 5L;

  @Test
  void eventBus_deliversSyntheticTimelineEvent_withSessionMetadata() throws Exception {
    val timelineStub =
        new EventBusSubscription() {
          @Override
          public Subscription.RequestCase subscriptionCase() {
            return Subscription.RequestCase.TIMELINE;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final Subscription subscription) {
            session.emit(
                Event.newBuilder()
                    .setSubscriptionId(subscription.getSubscriptionId())
                    .setTimeline(
                        SubscribeTimelineResponse.newBuilder().addPostIds("stub-post").build())
                    .build());
            return () -> {};
          }
        };
    try (InProcessEventBus grpc = new InProcessEventBus(List.of(timelineStub))) {
      val subscriptionId = UUID.randomUUID().toString();
      val gotEvent = new CountDownLatch(1);
      val error = new AtomicReference<String>();
      grpc.asyncStub()
          .eventBus(
              EventBusRequest.newBuilder()
                  .setContext(context("test", 0))
                  .addSubscriptions(
                      Subscription.newBuilder()
                          .setSubscriptionId(subscriptionId)
                          .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
                          .build())
                  .build(),
              new StreamObserver<Event>() {
                @Override
                public void onNext(final Event event) {
                  if (subscriptionId.equals(event.getSubscriptionId())
                      && event.hasTimeline()
                      && event.getTimeline().getPostIdsList().contains("stub-post")) {
                    gotEvent.countDown();
                  }
                }

                @Override
                public void onError(final Throwable throwable) {
                  error.set(throwable.getMessage());
                }

                @Override
                public void onCompleted() {}
              });
      awaitLatch(gotEvent, error, STREAM_TIMEOUT_SECONDS);
    }
  }

  @Test
  void subscribeRpc_addsLikesSubscriptionOnActiveSession() throws Exception {
    val likesStub =
        new EventBusSubscription() {
          @Override
          public Subscription.RequestCase subscriptionCase() {
            return Subscription.RequestCase.LIKES;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final Subscription subscription) {
            session.emit(
                Event.newBuilder()
                    .setSubscriptionId(subscription.getSubscriptionId())
                    .setLikes(
                        SubscribeLikesResponse.newBuilder()
                            .setPostId(subscription.getLikes().getPostId())
                            .setLikeCount(7L)
                            .build())
                    .build());
            return () -> {};
          }
        };
    try (InProcessEventBus grpc = new InProcessEventBus(List.of(likesStub))) {
      val likesSubscriptionId = UUID.randomUUID().toString();
      val postId = "post-for-subscribe-rpc";
      val gotLikesEvent = new CountDownLatch(1);
      val error = new AtomicReference<String>();
      grpc.asyncStub()
          .eventBus(
              EventBusRequest.newBuilder().setContext(context("test", 0)).build(),
              new StreamObserver<Event>() {
                @Override
                public void onNext(final Event event) {
                  if (likesSubscriptionId.equals(event.getSubscriptionId())
                      && event.hasLikes()
                      && event.getLikes().getLikeCount() == 7L) {
                    gotLikesEvent.countDown();
                  }
                }

                @Override
                public void onError(final Throwable throwable) {
                  error.set(throwable.getMessage());
                }

                @Override
                public void onCompleted() {}
              });
      grpc.blockingStub()
          .subscribe(
              SubscribeRequest.newBuilder()
                  .setContext(context("test", 0))
                  .setSubscription(
                      Subscription.newBuilder()
                          .setSubscriptionId(likesSubscriptionId)
                          .setLikes(SubscribeLikesRequest.newBuilder().setPostId(postId).build())
                          .build())
                  .build());
      awaitLatch(gotLikesEvent, error, STREAM_TIMEOUT_SECONDS);
    }
  }

  @Test
  void subscribeRpc_secondSubscribeWithSameId_closesFirstHandle() throws Exception {
    val firstClosed = new AtomicBoolean(false);
    val secondClosed = new AtomicBoolean(false);
    val subscribeOrdinal = new AtomicInteger(0);
    val likesStub =
        new EventBusSubscription() {
          @Override
          public Subscription.RequestCase subscriptionCase() {
            return Subscription.RequestCase.LIKES;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final Subscription subscription) {
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
    try (InProcessEventBus grpc = new InProcessEventBus(List.of(likesStub))) {
      val likesSubscriptionId = UUID.randomUUID().toString();
      val error = new AtomicReference<String>();
      grpc.asyncStub()
          .eventBus(
              EventBusRequest.newBuilder().setContext(context("test", 0)).build(),
              InProcessEventBus.discardingEventObserver(error));
      val likesRequest =
          SubscribeRequest.newBuilder()
              .setContext(context("test", 0))
              .setSubscription(
                  Subscription.newBuilder()
                      .setSubscriptionId(likesSubscriptionId)
                      .setLikes(
                          SubscribeLikesRequest.newBuilder()
                              .setPostId("post-double-subscribe")
                              .build())
                      .build())
              .build();
      grpc.blockingStub().subscribe(likesRequest);
      assertFalse(firstClosed.get());
      grpc.blockingStub().subscribe(likesRequest);
      assertTrue(firstClosed.get());
      assertFalse(secondClosed.get());
      grpc.blockingStub()
          .unsubscribe(
              UnsubscribeRequest.newBuilder()
                  .setContext(context("test", 0))
                  .setSubscriptionId(likesSubscriptionId)
                  .build());
    }
  }

  @Test
  void unsubscribeRpc_closesLikesSubscription() throws Exception {
    val likesClosed = new AtomicBoolean(false);
    val likesStub =
        new EventBusSubscription() {
          @Override
          public Subscription.RequestCase subscriptionCase() {
            return Subscription.RequestCase.LIKES;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final Subscription subscription) {
            return () -> likesClosed.set(true);
          }
        };
    try (InProcessEventBus grpc = new InProcessEventBus(List.of(likesStub))) {
      val likesSubscriptionId = UUID.randomUUID().toString();
      val error = new AtomicReference<String>();
      grpc.asyncStub()
          .eventBus(
              EventBusRequest.newBuilder().setContext(context("test", 0)).build(),
              InProcessEventBus.discardingEventObserver(error));
      grpc.blockingStub()
          .subscribe(
              SubscribeRequest.newBuilder()
                  .setContext(context("test", 0))
                  .setSubscription(
                      Subscription.newBuilder()
                          .setSubscriptionId(likesSubscriptionId)
                          .setLikes(SubscribeLikesRequest.newBuilder().setPostId("any").build())
                          .build())
                  .build());
      assertFalse(
          likesClosed.get(), () -> error.get() != null ? error.get() : "timeout (no stream error)");
      grpc.blockingStub()
          .unsubscribe(
              UnsubscribeRequest.newBuilder()
                  .setContext(context("test", 0))
                  .setSubscriptionId(likesSubscriptionId)
                  .build());
      assertTrue(likesClosed.get());
    }
  }

  @Test
  void eventBus_higherEpochClosesOlderSession() throws Exception {
    val firstEpochClosed = new CountDownLatch(1);
    val likesStub =
        new EventBusSubscription() {
          @Override
          public Subscription.RequestCase subscriptionCase() {
            return Subscription.RequestCase.LIKES;
          }

          @Override
          public AutoCloseable subscribe(
              final EventBusSession session, final Subscription subscription) {
            return firstEpochClosed::countDown;
          }
        };
    try (InProcessEventBus grpc = new InProcessEventBus(List.of(likesStub))) {
      val sessionId = "shared-session-id";
      val firstContext = context(sessionId, 0);
      val secondContext = context(sessionId, 1);
      val error = new AtomicReference<String>();
      grpc.asyncStub()
          .eventBus(
              EventBusRequest.newBuilder().setContext(firstContext).build(),
              InProcessEventBus.discardingEventObserver(error));
      grpc.blockingStub()
          .subscribe(
              SubscribeRequest.newBuilder()
                  .setContext(firstContext)
                  .setSubscription(
                      Subscription.newBuilder()
                          .setSubscriptionId(UUID.randomUUID().toString())
                          .setLikes(SubscribeLikesRequest.newBuilder().setPostId("any").build())
                          .build())
                  .build());
      grpc.asyncStub()
          .eventBus(
              EventBusRequest.newBuilder().setContext(secondContext).build(),
              InProcessEventBus.discardingEventObserver(error));
      awaitLatch(firstEpochClosed, error, STREAM_TIMEOUT_SECONDS);
    }
  }

  @Test
  void eventBus_cancelledStream_rejectsLaterSubscribe() throws Exception {
    try (InProcessEventBus grpc = new InProcessEventBus(List.of())) {
      val context = context("test", 0);
      val cancellable = Context.current().withCancellation();
      cancellable.run(
          () ->
              grpc.asyncStub()
                  .eventBus(
                      EventBusRequest.newBuilder().setContext(context).build(),
                      InProcessEventBus.discardingEventObserver(new AtomicReference<>())));
      cancellable.cancel(null);
      val thrown =
          assertThrows(
              StatusRuntimeException.class,
              () ->
                  grpc.blockingStub()
                      .subscribe(
                          SubscribeRequest.newBuilder()
                              .setContext(context)
                              .setSubscription(
                                  Subscription.newBuilder()
                                      .setSubscriptionId(UUID.randomUUID().toString())
                                      .setLikes(
                                          SubscribeLikesRequest.newBuilder()
                                              .setPostId("any")
                                              .build())
                                      .build())
                              .build()));
      assertEquals(Status.Code.FAILED_PRECONDITION, thrown.getStatus().getCode());
    }
  }

  public static void awaitLatch(
      final CountDownLatch latch, final AtomicReference<String> error, final long timeoutSeconds)
      throws InterruptedException {
    assertTrue(
        latch.await(timeoutSeconds, TimeUnit.SECONDS),
        () -> {
          val message = error.get();
          return message != null ? message : "timeout (no stream error)";
        });
  }
}
