package social.example.features.timeline;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static social.example.features.timeline.TimelineTestSupport.awaitTimelinePostIds;
import static social.example.features.timeline.TimelineTestSupport.awaitTimelineUntil;

import java.util.List;
import java.util.UUID;
import lombok.val;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;
import social.example.features.FeatureFixture;
import social.example.features.posts.PostFeature;

class TimelineFeatureTest {
  private static final long SETTLE_MILLIS = 200L;

  @RegisterExtension
  final FeatureFixture fixture = new FeatureFixture(new PostFeature(), new TimelineFeature());

  @Test
  void postIdsAppendInOrder() throws Exception {
    val first = fixture.api().createPost("a").postId();
    val second = fixture.api().createPost("b").postId();
    val third = fixture.api().createPost("c").postId();
    awaitTimelinePostIds(fixture.cluster(), List.of(first, second, third));

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));

    assertEquals(
        List.of(EventBusServerMessage.timeline(subscriptionId, List.of(first, second, third))),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void duplicateAddId_isIdempotent() throws Exception {
    val sharedId = fixture.api().createPost("a").postId();
    val secondPostId = fixture.api().createPost("b").postId();
    fixture.api().editPost(sharedId, "a-edited");
    awaitTimelineUntil(
        fixture.cluster(),
        postIds -> postIds.size() == 2 && sharedId.equals(postIds.getFirst()),
        "timeline should list exactly two post ids with "
            + sharedId
            + " first after duplicate edit");

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));

    assertEquals(
        List.of(EventBusServerMessage.timeline(subscriptionId, List.of(sharedId, secondPostId))),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void deleteEventDropsId() throws Exception {
    val goneId = fixture.api().createPost("gone").postId();
    val stayId = fixture.api().createPost("stay").postId();
    fixture.api().deletePost(goneId);
    awaitTimelinePostIds(fixture.cluster(), List.of(stayId));

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));

    assertEquals(
        List.of(EventBusServerMessage.timeline(subscriptionId, List.of(stayId))),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void subscribeTimeline_beforeAnyPost_emitsEmptyTimelineSnapshot() throws Exception {
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));

    assertEquals(
        List.of(EventBusServerMessage.timeline(subscriptionId, List.of())),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void subscribeTimeline_afterPost_emitsSnapshotWithPostId() throws Exception {
    val postId = fixture.api().createPost("body").postId();
    awaitTimelinePostIds(fixture.cluster(), List.of(postId));

    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));

    assertEquals(
        List.of(EventBusServerMessage.timeline(subscriptionId, List.of(postId))),
        fixture.awaitAndDrainEventBusEvents(1));
  }

  @Test
  void subscribeTimeline_emitsNewPostWhileSubscribed() throws Exception {
    val subscriptionId = UUID.randomUUID().toString();
    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));
    fixture.awaitAndDrainEventBusEvents(1);

    val laterPost = fixture.api().createPost("later");

    fixture.awaitEventBusEvent(
        event ->
            subscriptionId.equals(event.subscriptionId())
                && event.timeline() != null
                && event.timeline().postIds().contains(laterPost.postId()),
        "timeline subscription should emit post id " + laterPost.postId() + " after create");
  }

  @Test
  void subscribeTimeline_unsubscribeStopsFurtherTimelineEvents() throws Exception {
    val subscriptionId = UUID.randomUUID().toString();

    fixture.subscribe(SubscribeCommand.timeline(subscriptionId));

    assertEquals(
        List.of(EventBusServerMessage.timeline(subscriptionId, List.of())),
        fixture.awaitAndDrainEventBusEvents(1));

    fixture.unsubscribe(subscriptionId);
    fixture.assertNoEventBusEventsWithin(SETTLE_MILLIS);

    fixture.api().createPost("later");
    awaitTimelineUntil(
        fixture.cluster(),
        postIds -> !postIds.isEmpty(),
        "timeline should receive post after unsubscribe");

    fixture.assertNoEventBusEventsWithin(SETTLE_MILLIS);
  }
}
