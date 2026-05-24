package social.example.features.posts;

import com.rpl.rama.RamaSerializable;
import social.example.features.posts.grpc.Post;

public record RamaPostEvent(String postId, String body, long postedAtMillis, boolean deleted)
    implements RamaSerializable {

  public Post toProto() {
    return Post.newBuilder()
        .setPostId(postId)
        .setBody(body)
        .setPostedAtMillis(postedAtMillis)
        .build();
  }
}
