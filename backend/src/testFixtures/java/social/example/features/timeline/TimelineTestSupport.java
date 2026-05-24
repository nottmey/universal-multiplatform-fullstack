package social.example.features.timeline;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.rpl.rama.Path;
import com.rpl.rama.test.InProcessCluster;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.function.Predicate;
import lombok.val;

public final class TimelineTestSupport {
  private static final long DEFAULT_TIMEOUT_MILLIS = 2000L;
  private static final long POLL_INTERVAL_MILLIS = 5L;

  private TimelineTestSupport() {}

  public static void awaitTimelinePostIds(
      final InProcessCluster cluster, final List<String> expectedPostIds)
      throws InterruptedException {
    val currentTimeline = pollTimelineUntil(cluster, expectedPostIds::equals);
    assertEquals(expectedPostIds, currentTimeline);
  }

  public static void awaitTimelineUntil(
      final InProcessCluster cluster,
      final Predicate<List<String>> predicate,
      final String expectedDescription)
      throws InterruptedException {
    val currentTimeline = pollTimelineUntil(cluster, predicate);
    assertTrue(predicate.test(currentTimeline), expectedDescription);
  }

  @SuppressWarnings("unchecked")
  private static List<String> pollTimelineUntil(
      final InProcessCluster cluster, final Predicate<List<String>> condition)
      throws InterruptedException {
    val timeline = cluster.clusterPState(TimelineModule.NAME, TimelineModule.TIMELINE_PSTATE);
    val deadlineNanos = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(DEFAULT_TIMEOUT_MILLIS);
    List<String> currentTimeline;
    do {
      Thread.sleep(POLL_INTERVAL_MILLIS);
      val postIds = (List<String>) timeline.selectOne(Path.key(TimelineModule.GLOBAL_TIMELINE_KEY));
      currentTimeline = postIds == null ? List.of() : postIds;
    } while (!condition.test(currentTimeline) && System.nanoTime() < deadlineNanos);
    return currentTimeline;
  }
}
