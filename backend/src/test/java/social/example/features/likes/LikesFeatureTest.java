package social.example.features.likes;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.Subscription;
import social.example.features.FeatureFixture;
import social.example.features.likes.grpc.LikeRequest;
import social.example.features.likes.grpc.LikesServiceGrpc;
import social.example.features.likes.grpc.SubscribeLikesRequest;
import social.example.features.likes.grpc.SubscribeLikesResponse;

class LikesFeatureTest {
  @RegisterExtension final FeatureFixture fixture = new FeatureFixture(new LikesFeature());

  private LikesServiceGrpc.LikesServiceBlockingStub likesStub;

  @BeforeEach
  void bindClients() {
    likesStub = fixture.stub(LikesServiceGrpc::newBlockingStub);
  }

  @Test
  void like_firstLikeReturnsOneAndIncrementsPerPost() {
    val postA = UUID.randomUUID().toString();
    val postB = UUID.randomUUID().toString();

    val firstLikeOnA = likesStub.like(LikeRequest.newBuilder().setPostId(postA).build());
    val secondLikeOnA = likesStub.like(LikeRequest.newBuilder().setPostId(postA).build());
    val likeOnB = likesStub.like(LikeRequest.newBuilder().setPostId(postB).build());

    assertEquals(postA, firstLikeOnA.getPostId());
    assertEquals(1L, firstLikeOnA.getLikeCount());
    assertEquals(2L, secondLikeOnA.getLikeCount());
    assertEquals(postB, likeOnB.getPostId());
    assertEquals(1L, likeOnB.getLikeCount());
    assertEquals(List.of(), fixture.drainEventBusEvents());
  }

  @Test
  void subscribeLikes_emitsZeroCountBeforeAnyLike() {
    val postId = UUID.randomUUID().toString();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setLikes(SubscribeLikesRequest.newBuilder().setPostId(postId).build())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setLikes(
                    SubscribeLikesResponse.newBuilder().setPostId(postId).setLikeCount(0L).build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribeLikes_emitsIncrementWhileSubscribed() throws Exception {
    val postId = UUID.randomUUID().toString();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setLikes(SubscribeLikesRequest.newBuilder().setPostId(postId).build())
            .build());
    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setLikes(
                    SubscribeLikesResponse.newBuilder().setPostId(postId).setLikeCount(0L).build())
                .build()),
        fixture.drainEventBusEvents());

    likesStub.like(LikeRequest.newBuilder().setPostId(postId).build());

    fixture.awaitEventBusEvent(
        event ->
            subscriptionId.equals(event.getSubscriptionId())
                && event.hasLikes()
                && event.getLikes().getLikeCount() == 1L,
        "expected like_count 1 after like");
  }

  @Test
  void subscribeLikes_unsubscribeStopsFurtherEvents() {
    val postId = UUID.randomUUID().toString();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setLikes(SubscribeLikesRequest.newBuilder().setPostId(postId).build())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setLikes(
                    SubscribeLikesResponse.newBuilder().setPostId(postId).setLikeCount(0L).build())
                .build()),
        fixture.drainEventBusEvents());

    fixture.unsubscribe(subscriptionId);
    likesStub.like(LikeRequest.newBuilder().setPostId(postId).build());

    assertEquals(List.of(), fixture.drainEventBusEvents());
  }
}
