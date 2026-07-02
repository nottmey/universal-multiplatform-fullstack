package social.example.features.posts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static social.example.HttpTestSupport.assertNotFound;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;
import social.example.features.FeatureFixture;

class PostsFeatureTest {
  private static final long SETTLE_MILLIS = 200L;

  @RegisterExtension final FeatureFixture fixture = new FeatureFixture(new PostFeature());

  @Test
  void editPost_updatesBodyForSamePostId() {
    val first = fixture.api().createPost("first");
    fixture.api().createPost("second");
    val edited = fixture.api().editPost(first.postId(), "first-edited");

    assertEquals(first.postId(), edited.postId());
    assertEquals("first-edited", edited.body());
  }

  @Test
  void deletePost_succeedsTwiceSecondCallNotFound() {
    val postId = fixture.api().createPost("to-delete").postId();
    fixture.api().deletePost(postId);
    assertNotFound(fixture.api().tryDeletePost(postId));
  }

  @Test
  void editPost_returnsNotFound_afterDelete() {
    val postId = fixture.api().createPost("gone").postId();
    fixture.api().deletePost(postId);
    assertNotFound(fixture.api().tryEditPost(postId, "again"));
  }

  @Test
  void subscribePost_emitsCurrentPostAfterCreate() throws Exception {
    val created = fixture.api().createPost("subscribe-me");
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(SubscribeCommand.post(subscriptionId, created.postId()));

    assertEquals(
        List.of(EventBusServerMessage.post(subscriptionId, created)),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void subscribePost_emitsUpdatedBodyAfterEdit() throws Exception {
    val created = fixture.api().createPost("before-edit");
    val edited = fixture.api().editPost(created.postId(), "after-edit");

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(SubscribeCommand.post(subscriptionId, created.postId()));

    assertEquals(
        List.of(EventBusServerMessage.post(subscriptionId, edited)),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void subscribePost_emitsEditWhileSubscribed() throws Exception {
    val created = fixture.api().createPost("live-edit");
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(SubscribeCommand.post(subscriptionId, created.postId()));
    fixture.awaitAndDrainEventBusEvents(1);

    val edited = fixture.api().editPost(created.postId(), "live-edited");

    assertEquals(
        List.of(EventBusServerMessage.post(subscriptionId, edited)),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void subscribePost_doesNotEmitBodyUpdateAfterDelete() throws Exception {
    val created = fixture.api().createPost("will-delete");
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(SubscribeCommand.post(subscriptionId, created.postId()));
    fixture.awaitAndDrainEventBusEvents(1);

    fixture.api().deletePost(created.postId());

    Thread.sleep(SETTLE_MILLIS);
    val eventsAfterDelete = fixture.drainEventBusEvents();
    val sawEditedBodyAfterDelete =
        eventsAfterDelete.stream()
            .anyMatch(
                event ->
                    subscriptionId.equals(event.subscriptionId())
                        && event.post() != null
                        && event.post().post() != null
                        && "will-delete".equals(event.post().post().body()));
    assertEquals(false, sawEditedBodyAfterDelete);
  }

  @Test
  void subscribePost_unsubscribeStopsFurtherEvents() throws Exception {
    val created = fixture.api().createPost("watch-close");
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(SubscribeCommand.post(subscriptionId, created.postId()));

    assertEquals(
        List.of(EventBusServerMessage.post(subscriptionId, created)),
        fixture.awaitAndDrainEventBusEvents(1));

    fixture.unsubscribe(subscriptionId);
    fixture.assertNoEventBusEventsWithin(SETTLE_MILLIS);
    fixture.api().editPost(created.postId(), "after-close");

    fixture.assertNoEventBusEventsWithin(SETTLE_MILLIS);
  }
}
