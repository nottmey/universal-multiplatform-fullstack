package social.example.features.posts;

import static social.example.GrpcTestSupport.assertInvalidArgument;
import static social.example.GrpcTestSupport.assertNotFound;
import static social.example.GrpcTestSupport.context;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import social.example.RamaTestStubs;
import social.example.eventbus.InProcessEventBus;
import social.example.eventbus.grpc.Subscription;
import social.example.features.InputValidationFixture;
import social.example.features.posts.grpc.CreatePostRequest;
import social.example.features.posts.grpc.DeletePostRequest;
import social.example.features.posts.grpc.EditPostRequest;
import social.example.features.posts.grpc.PostServiceGrpc;
import social.example.features.posts.grpc.SubscribePostRequest;

class PostsInputValidationTest {
  @RegisterExtension
  final InputValidationFixture fixture =
      new InputValidationFixture(
          new PostService(RamaTestStubs.throwingDepot(), RamaTestStubs.emptyPState()));

  private PostServiceGrpc.PostServiceBlockingStub postsStub;

  @BeforeEach
  void bindClients() {
    postsStub = fixture.stub(PostServiceGrpc::newBlockingStub);
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankPostId_onRpc(final String postId) {
    assertInvalidArgument(
        () ->
            postsStub.editPost(
                EditPostRequest.newBuilder().setPostId(postId).setBody("hello").build()),
        "post_id is required");
    assertInvalidArgument(
        () -> postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(postId).build()),
        "post_id is required");
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankPostId_onSubscribe(final String postId) throws Exception {
    val context = context("test", 0);
    try (val eventBus =
        new InProcessEventBus(List.of(new PostSubscription(RamaTestStubs.emptyPState())))) {
      eventBus.openEventBusWithDiscardedResponses(context);
      assertInvalidArgument(
          () ->
              eventBus.subscribe(
                  context,
                  Subscription.newBuilder()
                      .setSubscriptionId(UUID.randomUUID().toString())
                      .setPost(SubscribePostRequest.newBuilder().setPostId(postId).build())
                      .build()),
          "post_id is required");
    }
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankBody(final String body) {
    assertInvalidArgument(
        () -> postsStub.createPost(CreatePostRequest.newBuilder().setBody(body).build()),
        "body is required");

    val postId = UUID.randomUUID().toString();
    assertInvalidArgument(
        () ->
            postsStub.editPost(
                EditPostRequest.newBuilder().setPostId(postId).setBody(body).build()),
        "body is required");
  }

  @Test
  void editPost_returnsNotFound_whenPostMissing() {
    val missingPostId = UUID.randomUUID().toString();
    assertNotFound(
        () ->
            postsStub.editPost(
                EditPostRequest.newBuilder().setPostId(missingPostId).setBody("hello").build()));
  }

  @Test
  void deletePost_returnsNotFound_whenPostMissing() {
    val missingPostId = UUID.randomUUID().toString();
    assertNotFound(
        () ->
            postsStub.deletePost(DeletePostRequest.newBuilder().setPostId(missingPostId).build()));
  }
}
