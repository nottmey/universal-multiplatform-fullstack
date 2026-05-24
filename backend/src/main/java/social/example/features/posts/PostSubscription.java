package social.example.features.posts;

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
import social.example.features.posts.grpc.SubscribePostResponse;
import social.example.utils.CloseQuietly;

@RequiredArgsConstructor
public class PostSubscription implements EventBusSubscription {
  private final PState postsPState;

  @Override
  public Subscription.RequestCase subscriptionCase() {
    return Subscription.RequestCase.POST;
  }

  @Override
  public AutoCloseable subscribe(final EventBusSession session, final Subscription subscription) {
    val postId = subscription.getPost().getPostId();
    if (postId.isBlank()) {
      throw Status.INVALID_ARGUMENT.withDescription("post_id is required").asRuntimeException();
    }
    ProxyState<RamaPostView> proxy =
        postsPState.proxy(
            Path.key(postId),
            (newVal, diff, oldVal) -> {
              if (diff instanceof DestroyedDiff) {
                return;
              }
              session.emit(
                  Event.newBuilder()
                      .setSubscriptionId(subscription.getSubscriptionId())
                      .setPost(
                          newVal == null
                              ? SubscribePostResponse.newBuilder().build()
                              : SubscribePostResponse.newBuilder()
                                  .setPost(newVal.toProto())
                                  .build())
                      .build());
            });
    return () -> CloseQuietly.close(proxy);
  }
}
