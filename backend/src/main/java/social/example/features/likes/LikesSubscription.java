package social.example.features.likes;

import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.ProxyState;
import com.rpl.rama.diffs.DestroyedDiff;
import io.grpc.Status;
import lombok.RequiredArgsConstructor;
import lombok.val;
import social.example.eventbus.EventBusSession;
import social.example.eventbus.EventBusSubscription;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.Subscription;
import social.example.utils.CloseQuietly;

@RequiredArgsConstructor
public class LikesSubscription implements EventBusSubscription {
  private final PState likesPState;

  @Override
  public Subscription.RequestCase subscriptionCase() {
    return Subscription.RequestCase.LIKES;
  }

  @Override
  public AutoCloseable subscribe(final EventBusSession session, final Subscription subscription) {
    val likesRequest = subscription.getLikes();
    val postId = likesRequest.getPostId();
    if (postId.isBlank()) {
      throw Status.INVALID_ARGUMENT.withDescription("post_id is required").asRuntimeException();
    }
    ProxyState<RamaLikesView> proxy =
        likesPState.proxy(
            Path.key(postId),
            (newVal, diff, oldVal) -> {
              if (diff instanceof DestroyedDiff) {
                // DestroyedDiff is the last callback after the proxy is closed, not a data delete.
                return;
              }
              val payload =
                  newVal == null
                      ? RamaLikesView.emptySubscribeResponse(postId)
                      : newVal.toSubscribeLikesResponse();
              session.emit(
                  Event.newBuilder()
                      .setSubscriptionId(subscription.getSubscriptionId())
                      .setLikes(payload)
                      .build());
            });
    return () -> CloseQuietly.close(proxy);
  }
}
