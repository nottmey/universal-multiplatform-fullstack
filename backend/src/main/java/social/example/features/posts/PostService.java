package social.example.features.posts;

import com.rpl.rama.AckLevel;
import com.rpl.rama.Depot;
import com.rpl.rama.PState;
import com.rpl.rama.Path;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.StreamObserver;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.features.posts.grpc.CreatePostRequest;
import social.example.features.posts.grpc.CreatePostResponse;
import social.example.features.posts.grpc.DeletePostRequest;
import social.example.features.posts.grpc.DeletePostResponse;
import social.example.features.posts.grpc.EditPostRequest;
import social.example.features.posts.grpc.EditPostResponse;
import social.example.features.posts.grpc.PostServiceGrpc;

@Log4j2
@RequiredArgsConstructor
public class PostService extends PostServiceGrpc.PostServiceImplBase {
  private final Depot postsDepot;
  private final PState postsPState;

  @Override
  public void createPost(
      final CreatePostRequest request, final StreamObserver<CreatePostResponse> response) {
    try {
      val body = request.getBody();
      if (body.isBlank()) {
        response.onError(
            Status.INVALID_ARGUMENT.withDescription("body is required").asRuntimeException());
        return;
      }
      val ack =
          postsDepot.append(
              new RamaPostEvent(
                  UUID.randomUUID().toString(), body, System.currentTimeMillis(), false),
              AckLevel.ACK);
      val created = (RamaPostEvent) ack.get(PostsModule.POSTS_STREAM);
      response.onNext(CreatePostResponse.newBuilder().setPost(created.toProto()).build());
      response.onCompleted();
    } catch (final StatusRuntimeException e) {
      log.warn("createPost: gRPC failure", e);
      response.onError(e);
    } catch (final Exception e) {
      log.error("createPost: unexpected failure", e);
      response.onError(
          Status.INTERNAL.withCause(e).withDescription(e.getMessage()).asRuntimeException());
    }
  }

  @Override
  public void editPost(
      final EditPostRequest request, final StreamObserver<EditPostResponse> response) {
    try {
      val postId = request.getPostId();
      val body = request.getBody();
      if (postId.isBlank()) {
        response.onError(
            Status.INVALID_ARGUMENT.withDescription("post_id is required").asRuntimeException());
        return;
      }
      if (body.isBlank()) {
        response.onError(
            Status.INVALID_ARGUMENT.withDescription("body is required").asRuntimeException());
        return;
      }
      if (findPostView(postId).isEmpty()) {
        response.onError(Status.NOT_FOUND.withDescription("post not found").asRuntimeException());
        return;
      }
      val ack =
          postsDepot.append(
              new RamaPostEvent(postId, body, System.currentTimeMillis(), false), AckLevel.ACK);
      val updated = (RamaPostEvent) ack.get(PostsModule.POSTS_STREAM);
      response.onNext(EditPostResponse.newBuilder().setPost(updated.toProto()).build());
      response.onCompleted();
    } catch (final StatusRuntimeException e) {
      log.warn("editPost: gRPC failure", e);
      response.onError(e);
    } catch (final Exception e) {
      log.error("editPost: unexpected failure", e);
      response.onError(
          Status.INTERNAL.withCause(e).withDescription(e.getMessage()).asRuntimeException());
    }
  }

  @Override
  public void deletePost(
      final DeletePostRequest request, final StreamObserver<DeletePostResponse> response) {
    try {
      val postId = request.getPostId();
      if (postId.isBlank()) {
        response.onError(
            Status.INVALID_ARGUMENT.withDescription("post_id is required").asRuntimeException());
        return;
      }
      if (findPostView(postId).isEmpty()) {
        response.onError(Status.NOT_FOUND.withDescription("post not found").asRuntimeException());
        return;
      }
      postsDepot.append(
          new RamaPostEvent(postId, "", System.currentTimeMillis(), true), AckLevel.ACK);
      response.onNext(DeletePostResponse.getDefaultInstance());
      response.onCompleted();
    } catch (final StatusRuntimeException e) {
      log.warn("deletePost: gRPC failure", e);
      response.onError(e);
    } catch (final Exception e) {
      log.error("deletePost: unexpected failure", e);
      response.onError(
          Status.INTERNAL.withCause(e).withDescription(e.getMessage()).asRuntimeException());
    }
  }

  private Optional<RamaPostView> findPostView(final String postId) {
    val view = (RamaPostView) postsPState.selectOne(Path.key(postId));
    return Optional.ofNullable(view);
  }
}
