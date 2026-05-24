package social.example.features.timeline.aggregations;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotSame;

import java.util.List;
import lombok.val;
import org.junit.jupiter.api.Test;
import social.example.features.posts.RamaPostEvent;

class TimelinePostIdsMergeTest {
  @Test
  void timelinePostIdsMerge_nullCurrent_appendsPostId() {
    val merged =
        TimelinePostIdsMerge.INSTANCE.invoke(null, new RamaPostEvent("only", "body", 1L, false));
    assertEquals(List.of("only"), merged);
  }

  @Test
  void timelinePostIdsMerge_duplicateId_returnsCopyWithoutGrowth() {
    val base = new java.util.ArrayList<>(List.of("same"));
    val merged =
        TimelinePostIdsMerge.INSTANCE.invoke(base, new RamaPostEvent("same", "edited", 2L, false));
    assertEquals(List.of("same"), merged);
    assertNotSame(base, merged);
  }

  @Test
  void timelinePostIdsMerge_deleteRemovesId() {
    val merged =
        TimelinePostIdsMerge.INSTANCE.invoke(
            List.of("stay", "gone"), new RamaPostEvent("gone", "", 3L, true));
    assertEquals(List.of("stay"), merged);
  }
}
