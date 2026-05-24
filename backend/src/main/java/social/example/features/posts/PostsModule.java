package social.example.features.posts;

import com.rpl.rama.Depot;
import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.RamaModule;
import com.rpl.rama.ops.RamaFunction1;
import lombok.val;
import social.example.features.posts.aggregations.PostsMapMerge;

public class PostsModule implements RamaModule {
  public static final String NAME = PostsModule.class.getName();

  public static final String POSTS_STREAM = "posts";

  public static final String POSTS_DEPOT = "*posts";
  public static final String POSTS_PSTATE = "$$posts";

  @Override
  public void define(final Setup setup, final Topologies topologies) {
    setup.declareDepot(POSTS_DEPOT, Depot.hashBy(PartitionKey.class));

    val stream = topologies.stream(POSTS_STREAM);
    stream.pstate(POSTS_PSTATE, PState.mapSchema(String.class, RamaPostView.class)).global();
    stream
        .source(POSTS_DEPOT)
        .out("*event")
        .each(PostIdFromEvent.INSTANCE, "*event")
        .out("*postId")
        .globalPartition()
        .localTransform(POSTS_PSTATE, Path.key("*postId").term(PostsMapMerge.INSTANCE, "*event"))
        .ackReturn("*event");
  }

  static class PostIdFromEvent implements RamaFunction1<RamaPostEvent, String> {
    static final PostIdFromEvent INSTANCE = new PostIdFromEvent();

    private PostIdFromEvent() {}

    @Override
    public String invoke(final RamaPostEvent event) {
      return event.postId();
    }
  }

  public static class PartitionKey implements RamaFunction1<RamaPostEvent, String> {
    @Override
    public String invoke(final RamaPostEvent event) {
      return event.postId();
    }
  }
}
