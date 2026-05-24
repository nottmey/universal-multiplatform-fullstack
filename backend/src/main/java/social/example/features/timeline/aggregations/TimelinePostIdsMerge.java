package social.example.features.timeline.aggregations;

import com.rpl.rama.ops.RamaFunction2;
import java.util.ArrayList;
import java.util.List;
import lombok.val;
import social.example.features.posts.RamaPostEvent;

public final class TimelinePostIdsMerge
    implements RamaFunction2<List<String>, RamaPostEvent, List<String>> {
  public static final TimelinePostIdsMerge INSTANCE = new TimelinePostIdsMerge();

  private TimelinePostIdsMerge() {}

  @Override
  public List<String> invoke(final List<String> current, final RamaPostEvent incoming) {
    val base = current == null ? List.<String>of() : current;
    if (incoming.deleted()) {
      val next = new ArrayList<String>(base.size());
      for (val id : base) {
        if (!id.equals(incoming.postId())) {
          next.add(id);
        }
      }
      return next;
    }
    if (base.contains(incoming.postId())) {
      return new ArrayList<>(base);
    }
    val next = new ArrayList<String>(base.size() + 1);
    next.addAll(base);
    next.add(incoming.postId());
    return next;
  }
}
