package social.example.features.posts;

import com.rpl.rama.RamaSerializable;
import social.example.api.Post;

public record RamaPostEvent(String postId, String body, long postedAtMillis, boolean deleted)
    implements RamaSerializable {

  public Post toApi() {
    return new Post(postId, body, postedAtMillis);
  }
}
