package social.example.features.timeline;

import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.RamaModule;
import lombok.val;
import social.example.features.posts.PostsModule;
import social.example.features.timeline.aggregations.TimelinePostIdsMerge;

public class TimelineModule implements RamaModule {
  public static final String NAME = TimelineModule.class.getName();

  public static final String TIMELINE_STREAM = "timeline";

  public static final String MIRROR_POSTS_DEPOT = "*posts";
  public static final String TIMELINE_PSTATE = "$$timeline";

  public static final String GLOBAL_TIMELINE_KEY = "all";

  @Override
  public void define(final Setup setup, final Topologies topologies) {
    setup.clusterDepot(MIRROR_POSTS_DEPOT, PostsModule.NAME, PostsModule.POSTS_DEPOT);

    val stream = topologies.stream(TIMELINE_STREAM);
    stream
        .pstate(TIMELINE_PSTATE, PState.mapSchema(String.class, PState.listSchema(String.class)))
        .global();
    stream
        .source(MIRROR_POSTS_DEPOT)
        .out("*event")
        .globalPartition()
        .localTransform(
            TIMELINE_PSTATE,
            Path.key(GLOBAL_TIMELINE_KEY)
                .nullToList()
                .term(TimelinePostIdsMerge.INSTANCE, "*event"))
        .ackReturn("*event");
  }
}
