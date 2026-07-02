package social.example.features.posts;

import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.ProxyState;
import com.rpl.rama.diffs.DestroyedDiff;
import lombok.RequiredArgsConstructor;
import lombok.val;
import social.example.api.ApiException;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;
import social.example.eventbus.EventBusSession;
import social.example.eventbus.EventBusSubscription;
import social.example.eventbus.SubscriptionCase;
import social.example.utils.CloseQuietly;

@RequiredArgsConstructor
public class PostSubscription implements EventBusSubscription {
  private final PState postsPState;

  @Override
  public SubscriptionCase subscriptionCase() {
    return SubscriptionCase.POST;
  }

  @Override
  public AutoCloseable subscribe(final EventBusSession session, final SubscribeCommand command) {
    val postId = command.post().postId();
    if (postId == null || postId.isBlank()) {
      throw ApiException.invalidArgument("post_id is required");
    }
    ProxyState<RamaPostView> proxy =
        postsPState.proxy(
            Path.key(postId),
            (newVal, diff, oldVal) -> {
              if (diff instanceof DestroyedDiff) {
                return;
              }
              session.emit(
                  EventBusServerMessage.post(
                      command.subscriptionId(), newVal == null ? null : newVal.toApi()));
            });
    return () -> CloseQuietly.close(proxy);
  }
}
