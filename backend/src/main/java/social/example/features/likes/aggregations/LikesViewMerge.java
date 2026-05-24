package social.example.features.likes.aggregations;

import com.rpl.rama.ops.RamaFunction2;
import lombok.val;
import social.example.features.likes.RamaLikeEvent;
import social.example.features.likes.RamaLikesView;

public final class LikesViewMerge
    implements RamaFunction2<RamaLikesView, RamaLikeEvent, RamaLikesView> {
  public static final LikesViewMerge INSTANCE = new LikesViewMerge();

  private LikesViewMerge() {}

  @Override
  public RamaLikesView invoke(final RamaLikesView current, final RamaLikeEvent event) {
    val postId = event.postId();
    if (current == null) {
      return new RamaLikesView(postId, 1L);
    }
    return new RamaLikesView(postId, current.likeCount() + 1L);
  }
}
