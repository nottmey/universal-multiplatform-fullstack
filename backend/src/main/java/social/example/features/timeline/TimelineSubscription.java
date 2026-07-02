package social.example.features.timeline;

import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.ProxyState;
import com.rpl.rama.diffs.DestroyedDiff;
import java.util.List;
import lombok.RequiredArgsConstructor;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;
import social.example.eventbus.EventBusSession;
import social.example.eventbus.EventBusSubscription;
import social.example.eventbus.SubscriptionCase;
import social.example.utils.CloseQuietly;

@RequiredArgsConstructor
public class TimelineSubscription implements EventBusSubscription {
  private final PState timelinePState;

  @Override
  public SubscriptionCase subscriptionCase() {
    return SubscriptionCase.TIMELINE;
  }

  @Override
  public AutoCloseable subscribe(final EventBusSession session, final SubscribeCommand command) {
    ProxyState<List<String>> proxy =
        timelinePState.proxy(
            Path.key(TimelineModule.GLOBAL_TIMELINE_KEY),
            (newVal, diff, oldVal) -> {
              if (diff instanceof DestroyedDiff) {
                return;
              }
              List<String> ids = newVal == null ? List.of() : newVal;
              session.emit(EventBusServerMessage.timeline(command.subscriptionId(), ids));
            });
    return () -> CloseQuietly.close(proxy);
  }
}
