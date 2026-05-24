package social.example.features.posts;

import com.rpl.rama.RamaSerializable;
import social.example.features.posts.grpc.Post;

public record RamaPostView(String postId, String body, long postedAtMillis)
    implements RamaSerializable {

  public static RamaPostView from(final RamaPostEvent event) {
    return new RamaPostView(event.postId(), event.body(), event.postedAtMillis());
  }

  public Post toProto() {
    return Post.newBuilder()
        .setPostId(postId)
        .setBody(body)
        .setPostedAtMillis(postedAtMillis)
        .build();
  }
}
