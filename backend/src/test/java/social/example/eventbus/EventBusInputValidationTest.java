package social.example.eventbus;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static social.example.GrpcTestSupport.assertInvalidArgument;
import static social.example.GrpcTestSupport.context;

import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import social.example.eventbus.grpc.EventBusRequest;
import social.example.eventbus.grpc.Subscription;
import social.example.features.likes.grpc.SubscribeLikesRequest;
import social.example.features.timeline.grpc.SubscribeTimelineRequest;

class EventBusInputValidationTest {
  @Test
  void subscribeRpc_failsWhenNoEventBusStream() throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      val thrown =
          assertThrows(
              StatusRuntimeException.class,
              () ->
                  eventBus.subscribe(
                      context("test", 0),
                      Subscription.newBuilder()
                          .setSubscriptionId(UUID.randomUUID().toString())
                          .setLikes(SubscribeLikesRequest.newBuilder().setPostId("orphan").build())
                          .build()));
      assertEquals(Status.Code.FAILED_PRECONDITION, thrown.getStatus().getCode());
    }
  }

  @Test
  void unsubscribeRpc_completesWhenNoEventBusStream() throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      assertDoesNotThrow(
          () -> eventBus.unsubscribe(context("test", 0), UUID.randomUUID().toString()));
    }
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void subscribeRpc_rejectsBlankSubscriptionId(final String subscriptionId) throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      val context = context("test", 0);
      eventBus.openEventBusWithDiscardedResponses(context);
      assertInvalidArgument(
          () ->
              eventBus.subscribe(
                  context,
                  Subscription.newBuilder()
                      .setSubscriptionId(subscriptionId)
                      .setLikes(SubscribeLikesRequest.newBuilder().setPostId("any").build())
                      .build()),
          "subscription_id is required");
    }
  }

  @Test
  void eventBus_rejectsMissingSubscriptionOneof() throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      val context = context("test", 0);
      eventBus.openEventBusWithDiscardedResponses(context);
      assertInvalidArgument(
          () ->
              eventBus.subscribe(
                  context,
                  Subscription.newBuilder()
                      .setSubscriptionId(UUID.randomUUID().toString())
                      .build()),
          "subscription oneof is required");
    }
  }

  @Test
  void subscribeRpc_rejectsUnimplementedSubscriptionCase() throws Exception {
    try (val eventBus = new InProcessEventBus(List.of())) {
      val context = context("test", 0);
      eventBus.openEventBusWithDiscardedResponses(context);
      val thrown =
          assertThrows(
              StatusRuntimeException.class,
              () ->
                  eventBus.subscribe(
                      context,
                      Subscription.newBuilder()
                          .setSubscriptionId(UUID.randomUUID().toString())
                          .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
                          .build()));
      assertEquals(Status.Code.UNIMPLEMENTED, thrown.getStatus().getCode());
    }
  }

  @Test
  void eventBus_rejectsUnsetConnectionContextOnStreamOpen() throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      assertInvalidArgument(
          () -> eventBus.blockingStub().eventBus(EventBusRequest.newBuilder().build()).hasNext(),
          "connection context id is required");
    }
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void eventBus_rejectsBlankConnectionContextIdOnStreamOpen(final String sessionId)
      throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      assertInvalidArgument(
          () -> {
            eventBus
                .blockingStub()
                .eventBus(EventBusRequest.newBuilder().setContext(context(sessionId, 0)).build())
                .hasNext();
          },
          "connection context id is required");
    }
  }

  @Test
  void eventBus_rejectsNegativeConnectionContextEpochOnStreamOpen() throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      assertInvalidArgument(
          () -> {
            eventBus
                .blockingStub()
                .eventBus(EventBusRequest.newBuilder().setContext(context("test", -1)).build())
                .hasNext();
          },
          "connection context epoch must be non-negative");
    }
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void subscribeRpc_rejectsBlankConnectionContextId(final String sessionId) throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      eventBus.openEventBusWithDiscardedResponses(context("test", 0));
      assertInvalidArgument(
          () ->
              eventBus.subscribe(
                  context(sessionId, 0),
                  Subscription.newBuilder()
                      .setSubscriptionId(UUID.randomUUID().toString())
                      .setLikes(SubscribeLikesRequest.newBuilder().setPostId("any").build())
                      .build()),
          "connection context id is required");
    }
  }

  @Test
  void subscribeRpc_rejectsNegativeConnectionContextEpoch() throws Exception {
    try (val eventBus = new InProcessEventBus()) {
      eventBus.openEventBusWithDiscardedResponses(context("test", 0));
      assertInvalidArgument(
          () ->
              eventBus.subscribe(
                  context("test", -1),
                  Subscription.newBuilder()
                      .setSubscriptionId(UUID.randomUUID().toString())
                      .setLikes(SubscribeLikesRequest.newBuilder().setPostId("any").build())
                      .build()),
          "connection context epoch must be non-negative");
    }
  }
}
