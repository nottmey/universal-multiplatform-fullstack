package social.example.features.likes;

import static social.example.GrpcTestSupport.assertInvalidArgument;
import static social.example.GrpcTestSupport.context;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import social.example.RamaTestStubs;
import social.example.eventbus.InProcessEventBus;
import social.example.eventbus.grpc.Subscription;
import social.example.features.InputValidationFixture;
import social.example.features.likes.grpc.LikeRequest;
import social.example.features.likes.grpc.LikesServiceGrpc;
import social.example.features.likes.grpc.SubscribeLikesRequest;

class LikesInputValidationTest {
  @RegisterExtension
  final InputValidationFixture fixture =
      new InputValidationFixture(new LikesService(RamaTestStubs.throwingDepot()));

  private LikesServiceGrpc.LikesServiceBlockingStub likesStub;

  @BeforeEach
  void bindClients() {
    likesStub = fixture.stub(LikesServiceGrpc::newBlockingStub);
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankPostId_onLike(final String postId) {
    assertInvalidArgument(
        () -> likesStub.like(LikeRequest.newBuilder().setPostId(postId).build()),
        "post_id is required");
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankPostId_onSubscribe(final String postId) throws Exception {
    val context = context("test", 0);
    try (val eventBus =
        new InProcessEventBus(List.of(new LikesSubscription(RamaTestStubs.emptyPState())))) {
      eventBus.openEventBusWithDiscardedResponses(context);
      assertInvalidArgument(
          () ->
              eventBus.subscribe(
                  context,
                  Subscription.newBuilder()
                      .setSubscriptionId(UUID.randomUUID().toString())
                      .setLikes(SubscribeLikesRequest.newBuilder().setPostId(postId).build())
                      .build()),
          "post_id is required");
    }
  }
}
