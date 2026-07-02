package social.example.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

/**
 * Server-to-client WebSocket envelope. Exactly one of {@code connectionReady}, {@code timeline},
 * {@code post}, or {@code error} is set, mirroring a proto oneof.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record EventBusServerMessage(
    String subscriptionId,
    ConnectionReady connectionReady,
    TimelineEvent timeline,
    PostEvent post,
    ApiError error) {

  public static EventBusServerMessage ready() {
    return new EventBusServerMessage(null, new ConnectionReady(), null, null, null);
  }

  public static EventBusServerMessage timeline(
      final String subscriptionId, final List<String> postIds) {
    return new EventBusServerMessage(subscriptionId, null, new TimelineEvent(postIds), null, null);
  }

  public static EventBusServerMessage post(final String subscriptionId, final Post post) {
    return new EventBusServerMessage(subscriptionId, null, null, new PostEvent(post), null);
  }

  public static EventBusServerMessage error(final String subscriptionId, final ApiError error) {
    return new EventBusServerMessage(subscriptionId, null, null, null, error);
  }
}
