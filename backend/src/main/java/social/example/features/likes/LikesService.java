package social.example.features.likes;

import com.rpl.rama.AckLevel;
import com.rpl.rama.Depot;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.features.likes.grpc.LikeRequest;
import social.example.features.likes.grpc.LikeResponse;
import social.example.features.likes.grpc.LikesServiceGrpc;

@Log4j2
@RequiredArgsConstructor
public class LikesService extends LikesServiceGrpc.LikesServiceImplBase {
  private final Depot likesDepot;

  @Override
  public void like(final LikeRequest request, final StreamObserver<LikeResponse> response) {
    try {
      val postId = request.getPostId();
      if (postId.isBlank()) {
        response.onError(
            Status.INVALID_ARGUMENT.withDescription("post_id is required").asRuntimeException());
        return;
      }
      val ack = likesDepot.append(new RamaLikeEvent(postId), AckLevel.ACK);
      val updated = (RamaLikesView) ack.get(LikesModule.LIKES_STREAM);
      response.onNext(updated.toLikeResponse());
      response.onCompleted();
    } catch (final StatusRuntimeException e) {
      log.warn("like: gRPC failure", e);
      response.onError(e);
    } catch (final Exception e) {
      log.error("like: unexpected failure", e);
      response.onError(
          Status.INTERNAL.withCause(e).withDescription(e.getMessage()).asRuntimeException());
    }
  }
}
