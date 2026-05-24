package social.example.features.likes;

import com.rpl.rama.Depot;
import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.RamaModule;
import com.rpl.rama.ops.RamaFunction1;
import lombok.val;
import social.example.features.likes.aggregations.LikesViewMerge;

public class LikesModule implements RamaModule {
  public static final String NAME = LikesModule.class.getName();

  public static final String LIKES_STREAM = "likes";

  public static final String LIKES_DEPOT = "*likes";
  public static final String LIKES_PSTATE = "$$likes";

  @Override
  public void define(final Setup setup, final Topologies topologies) {
    setup.declareDepot(LIKES_DEPOT, Depot.hashBy(PartitionKey.class));

    val stream = topologies.stream(LIKES_STREAM);
    stream.pstate(LIKES_PSTATE, PState.mapSchema(String.class, RamaLikesView.class)).global();
    stream
        .source(LIKES_DEPOT)
        .out("*event")
        .each(LikeEventPostId.INSTANCE, "*event")
        .out("*postId")
        .globalPartition()
        .localTransform(LIKES_PSTATE, Path.key("*postId").term(LikesViewMerge.INSTANCE, "*event"))
        .localSelect(LIKES_PSTATE, Path.key("*postId"))
        .out("*view")
        .ackReturn("*view");
  }

  static class LikeEventPostId implements RamaFunction1<RamaLikeEvent, String> {
    static final LikeEventPostId INSTANCE = new LikeEventPostId();

    private LikeEventPostId() {}

    @Override
    public String invoke(final RamaLikeEvent event) {
      return event.postId();
    }
  }

  public static class PartitionKey implements RamaFunction1<RamaLikeEvent, String> {
    @Override
    public String invoke(final RamaLikeEvent event) {
      return event.postId();
    }
  }
}
