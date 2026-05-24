package social.example.features.likes;

import com.rpl.rama.RamaSerializable;
import social.example.features.likes.grpc.LikeResponse;
import social.example.features.likes.grpc.SubscribeLikesResponse;

public record RamaLikesView(String postId, long likeCount) implements RamaSerializable {

  public LikeResponse toLikeResponse() {
    return LikeResponse.newBuilder().setPostId(postId).setLikeCount(likeCount).build();
  }

  public SubscribeLikesResponse toSubscribeLikesResponse() {
    return SubscribeLikesResponse.newBuilder().setPostId(postId).setLikeCount(likeCount).build();
  }

  public static SubscribeLikesResponse emptySubscribeResponse(final String postId) {
    return SubscribeLikesResponse.newBuilder().setPostId(postId).setLikeCount(0L).build();
  }
}
