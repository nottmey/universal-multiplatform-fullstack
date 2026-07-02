package social.example.api;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Client-to-server WebSocket envelope. Exactly one of {@code subscribe} or {@code unsubscribe} is
 * set, mirroring a proto oneof.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record EventBusClientMessage(SubscribeCommand subscribe, UnsubscribeCommand unsubscribe) {

  public static EventBusClientMessage subscribe(final SubscribeCommand subscribe) {
    return new EventBusClientMessage(subscribe, null);
  }

  public static EventBusClientMessage unsubscribe(final String subscriptionId) {
    return new EventBusClientMessage(null, new UnsubscribeCommand(subscriptionId));
  }
}
