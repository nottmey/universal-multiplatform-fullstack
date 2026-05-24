package social.example.features.posts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static social.example.GrpcTestSupport.assertNotFound;

import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.Subscription;
import social.example.features.FeatureFixture;
import social.example.features.posts.grpc.CreatePostRequest;
import social.example.features.posts.grpc.DeletePostRequest;
import social.example.features.posts.grpc.EditPostRequest;
import social.example.features.posts.grpc.PostServiceGrpc;
import social.example.features.posts.grpc.SubscribePostRequest;
import social.example.features.posts.grpc.SubscribePostResponse;

class PostsFeatureTest {
  @RegisterExtension final FeatureFixture fixture = new FeatureFixture(new PostFeature());

  private PostServiceGrpc.PostServiceBlockingStub postsStub;

  @BeforeEach
  void bindClients() {
    postsStub = fixture.stub(PostServiceGrpc::newBlockingStub);
  }

  @Test
  void editPost_updatesBodyForSamePostId() {
    val first =
        postsStub.createPost(CreatePostRequest.newBuilder().setBody("first").build()).getPost();
    postsStub.createPost(CreatePostRequest.newBuilder().setBody("second").build());
    val edited =
        postsStub
            .editPost(
                EditPostRequest.newBuilder()
                    .setPostId(first.getPostId())
                    .setBody("first-edited")
                    .build())
            .getPost();

    assertEquals(first.getPostId(), edited.getPostId());
    assertEquals("first-edited", edited.getBody());
  }

  @Test
  void deletePost_succeedsTwiceSecondCallNotFound() {
    val postId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("to-delete").build())
            .getPost()
            .getPostId();
    postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(postId).build());
    val thrown =
        assertThrows(
            StatusRuntimeException.class,
            () -> postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(postId).build()));
    assertEquals(Status.Code.NOT_FOUND, thrown.getStatus().getCode());
  }

  @Test
  void editPost_returnsNotFound_afterDelete() {
    val postId =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("gone").build())
            .getPost()
            .getPostId();
    postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(postId).build());
    assertNotFound(
        () ->
            postsStub.editPost(
                EditPostRequest.newBuilder().setPostId(postId).setBody("again").build()));
  }

  @Test
  void subscribePost_emitsCurrentPostAfterCreate() {
    val created =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("subscribe-me").build())
            .getPost();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setPost(SubscribePostRequest.newBuilder().setPostId(created.getPostId()).build())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setPost(SubscribePostResponse.newBuilder().setPost(created).build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribePost_emitsUpdatedBodyAfterEdit() {
    val created =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("before-edit").build())
            .getPost();
    val edited =
        postsStub
            .editPost(
                EditPostRequest.newBuilder()
                    .setPostId(created.getPostId())
                    .setBody("after-edit")
                    .build())
            .getPost();

    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setPost(SubscribePostRequest.newBuilder().setPostId(created.getPostId()).build())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setPost(SubscribePostResponse.newBuilder().setPost(edited).build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribePost_emitsEditWhileSubscribed() {
    val created =
        postsStub.createPost(CreatePostRequest.newBuilder().setBody("live-edit").build()).getPost();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setPost(SubscribePostRequest.newBuilder().setPostId(created.getPostId()).build())
            .build());
    fixture.drainEventBusEvents();

    val edited =
        postsStub
            .editPost(
                EditPostRequest.newBuilder()
                    .setPostId(created.getPostId())
                    .setBody("live-edited")
                    .build())
            .getPost();

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setPost(SubscribePostResponse.newBuilder().setPost(edited).build())
                .build()),
        fixture.drainEventBusEvents());
  }

  @Test
  void subscribePost_doesNotEmitBodyUpdateAfterDelete() {
    val created =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("will-delete").build())
            .getPost();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setPost(SubscribePostRequest.newBuilder().setPostId(created.getPostId()).build())
            .build());
    fixture.drainEventBusEvents();

    postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(created.getPostId()).build());

    val eventsAfterDelete = fixture.drainEventBusEvents();
    val sawEditedBodyAfterDelete =
        eventsAfterDelete.stream()
            .anyMatch(
                event ->
                    subscriptionId.equals(event.getSubscriptionId())
                        && event.hasPost()
                        && "will-delete".equals(event.getPost().getPost().getBody()));
    assertEquals(false, sawEditedBodyAfterDelete);
  }

  @Test
  void subscribePost_unsubscribeStopsFurtherEvents() {
    val created =
        postsStub
            .createPost(CreatePostRequest.newBuilder().setBody("watch-close").build())
            .getPost();
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(
        Subscription.newBuilder()
            .setSubscriptionId(subscriptionId)
            .setPost(SubscribePostRequest.newBuilder().setPostId(created.getPostId()).build())
            .build());

    assertEquals(
        List.of(
            Event.newBuilder()
                .setSubscriptionId(subscriptionId)
                .setPost(SubscribePostResponse.newBuilder().setPost(created).build())
                .build()),
        fixture.drainEventBusEvents());

    fixture.unsubscribe(subscriptionId);
    postsStub.editPost(
        EditPostRequest.newBuilder().setPostId(created.getPostId()).setBody("after-close").build());

    assertEquals(List.of(), fixture.drainEventBusEvents());
  }
}
