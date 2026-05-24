package social.example.features.timeline;

import com.rpl.rama.PState;
import com.rpl.rama.Path;
import com.rpl.rama.ProxyState;
import com.rpl.rama.diffs.DestroyedDiff;
import java.util.List;
import lombok.RequiredArgsConstructor;
import social.example.eventbus.EventBusSession;
import social.example.eventbus.EventBusSubscription;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.Subscription;
import social.example.features.timeline.grpc.SubscribeTimelineResponse;
import social.example.utils.CloseQuietly;

@RequiredArgsConstructor
public class TimelineSubscription implements EventBusSubscription {
  private final PState timelinePState;

  @Override
  public Subscription.RequestCase subscriptionCase() {
    return Subscription.RequestCase.TIMELINE;
  }

  @Override
  public AutoCloseable subscribe(final EventBusSession session, final Subscription subscription) {
    ProxyState<List<String>> proxy =
        timelinePState.proxy(
            Path.key(TimelineModule.GLOBAL_TIMELINE_KEY),
            (newVal, diff, oldVal) -> {
              if (diff instanceof DestroyedDiff) {
                return;
              }
              List<String> ids = newVal == null ? List.of() : newVal;
              session.emit(
                  Event.newBuilder()
                      .setSubscriptionId(subscription.getSubscriptionId())
                      .setTimeline(
                          SubscribeTimelineResponse.newBuilder().addAllPostIds(ids).build())
                      .build());
            });
    return () -> CloseQuietly.close(proxy);
  }
}
