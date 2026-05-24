package social.example.features.timeline;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static social.example.features.timeline.TimelineTestSupport.awaitTimelinePostIds;
import static social.example.features.timeline.TimelineTestSupport.awaitTimelineUntil;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.Subscription;
import social.example.features.FeatureFixture;
import social.example.features.posts.PostFeature;
import social.example.features.posts.grpc.CreatePostRequest;
import social.example.features.posts.grpc.DeletePostRequest;
import social.example.features.posts.grpc.EditPostRequest;
import social.example.features.posts.grpc.PostServiceGrpc;
import social.example.features.timeline.grpc.SubscribeTimelineRequest;
import social.example.features.timeline.grpc.SubscribeTimelineResponse;

class TimelineFeatureTest {
  @RegisterExtension
  final FeatureFixture fixture = new FeatureFixture(new PostFeature(), new TimelineFeature());

  private PostServiceGrpc.PostServiceBlockingStub postsStub;

  @BeforeEach
  void bindClients() {
    postsStub = fixture.stub(PostServiceGrpc::newBlockingStub);
  }

  @Test
  void postIdsAppendInOrder() throws Exception {
    val first =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("a").build())
            .getPost()
            .getPostId();
    val second =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("b").build())
            .getPost()
            .getPostId();
    val third =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("c").build())
            .getPost()
            .getPostId();
    awaitTimelinePostIds(fixture.cluster(), List.of(first, second, third));

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setTimeline(
                    SubscribeTimelineResponse.newBuilder()
                        .addAllPostIds(List.of(first, second, third))
                        .build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void duplicateAddId_isIdempotent() throws Exception {
    val sharedId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("a").build())
            .getPost()
            .getPostId();
    val secondPostId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("b").build())
            .getPost()
            .getPostId();
    postsStub.editPost(
        EditPostRequest.newBuilder().setPostId(sharedId).setBody("a-edited").build());
    awaitTimelineUntil(
        fixture.cluster(),
        postIds -> postIds.size() == 2 && sharedId.equals(postIds.getFirst()),
        "timeline should list exactly two post ids with "
            + sharedId
            + " first after duplicate edit");

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setTimeline(
                    SubscribeTimelineResponse.newBuilder()
                        .addPostIds(sharedId)
                        .addPostIds(secondPostId)
                        .build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void deleteEventDropsId() throws Exception {
    val goneId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("gone").build())
            .getPost()
            .getPostId();
    val stayId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("stay").build())
            .getPost()
            .getPostId();
    postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(goneId).build());
    awaitTimelinePostIds(fixture.cluster(), List.of(stayId));

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setTimeline(SubscribeTimelineResponse.newBuilder().addPostIds(stayId).build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribeTimeline_beforeAnyPost_emitsEmptyTimelineSnapshot() {
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setTimeline(SubscribeTimelineResponse.getDefaultInstance())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribeTimeline_afterPost_emitsSnapshotWithPostId() throws Exception {
    val postId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("body").build())
            .getPost()
            .getPostId();
    awaitTimelinePostIds(fixture.cluster(), List.of(postId));

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setTimeline(SubscribeTimelineResponse.newBuilder().addPostIds(postId).build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribeTimeline_emitsNewPostWhileSubscribed() throws Exception {
    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());
    fixture.drainEventBusEvents();

    val laterPost =
        postsStub.createPost(CreatePostRequest.newBuilder().setBody("later").build()).getPost();

    fixture.awaitEventBusEvent(
        event ->
            subscriptionId.equals(event.getSubscriptionId())
                && event.getTimeline().getPostIdsList().contains(laterPost.getPostId()),
        "timeline subscription should emit post id " + laterPost.getPostId() + " after create");
  }

  @Test
  void subscribeTimeline_unsubscribeStopsFurtherTimelineEvents() throws Exception {
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setTimeline(SubscribeTimelineRequest.getDefaultInstance())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setTimeline(SubscribeTimelineResponse.getDefaultInstance())
                .build()),
        fixture.drainEventBusEvents());

    fixture.unsubscribe(subscriptionId);

    postsStub.createPost(CreatePostRequest.newBuilder().setBody("later").build());
    awaitTimelineUntil(
        fixture.cluster(),
        postIds -> !postIds.isEmpty(),
        "timeline should receive post after unsubscribe");

    assertEquals(List.of(), fixture.drainEventBusEvents());
  }
}
