package social.example.features.posts.aggregations;

import com.rpl.rama.ops.RamaFunction2;
import social.example.features.posts.RamaPostEvent;
import social.example.features.posts.RamaPostView;

public final class PostsMapMerge
    implements RamaFunction2<RamaPostView, RamaPostEvent, RamaPostView> {
  public static final PostsMapMerge INSTANCE = new PostsMapMerge();

  private PostsMapMerge() {}

  @Override
  public RamaPostView invoke(final RamaPostView current, final RamaPostEvent incoming) {
    if (incoming.deleted()) {
      return null;
    }
    return RamaPostView.from(incoming);
  }
}
