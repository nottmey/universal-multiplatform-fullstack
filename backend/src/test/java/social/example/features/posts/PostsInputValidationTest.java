package social.example.features.posts;

import static social.example.HttpTestSupport.assertInvalidArgument;
import static social.example.HttpTestSupport.assertNotFound;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import social.example.RamaTestStubs;
import social.example.api.SubscribeCommand;
import social.example.eventbus.EventBusTestServer;
import social.example.features.InputValidationFixture;

class PostsInputValidationTest {
  @RegisterExtension
  final InputValidationFixture fixture =
      new InputValidationFixture(
          new PostController(RamaTestStubs.throwingDepot(), RamaTestStubs.emptyPState())
              ::registerRoutes);

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankPostId_onSubscribe(final String postId) throws Exception {
    try (val server =
            new EventBusTestServer(List.of(new PostSubscription(RamaTestStubs.emptyPState())));
        val client = server.connectTestUser()) {
      val subscriptionId = UUID.randomUUID().toString();
      client.subscribe(SubscribeCommand.post(subscriptionId, postId));
      client.awaitEvent(
          event ->
              subscriptionId.equals(event.subscriptionId())
                  && event.error() != null
                  && "INVALID_ARGUMENT".equals(event.error().code())
                  && "post_id is required".equals(event.error().message()),
          "expected INVALID_ARGUMENT error for blank post_id");
    }
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "  "})
  void rejectsBlankBody(final String body) {
    assertInvalidArgument(fixture.api().tryCreatePost(body), "body is required");

    val postId = UUID.randomUUID().toString();
    assertInvalidArgument(fixture.api().tryEditPost(postId, body), "body is required");
  }

  @Test
  void rejectsMissingBody() {
    assertInvalidArgument(fixture.api().tryCreatePost(null), "body is required");
  }

  @Test
  void editPost_returnsNotFound_whenPostMissing() {
    val missingPostId = UUID.randomUUID().toString();
    assertNotFound(fixture.api().tryEditPost(missingPostId, "hello"));
  }

  @Test
  void deletePost_returnsNotFound_whenPostMissing() {
    val missingPostId = UUID.randomUUID().toString();
    assertNotFound(fixture.api().tryDeletePost(missingPostId));
  }
}
