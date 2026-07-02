package social.example.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.javalin.openapi.OpenApiRequired;

/**
 * Adds a subscription on the EventBus connection. Exactly one of {@code timeline} or {@code post}
 * is set, mirroring a proto oneof.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record SubscribeCommand(
    @OpenApiRequired String subscriptionId,
    TimelineSubscriptionRequest timeline,
    PostSubscriptionRequest post) {

  public static SubscribeCommand timeline(final String subscriptionId) {
    return new SubscribeCommand(subscriptionId, new TimelineSubscriptionRequest(), null);
  }

  public static SubscribeCommand post(final String subscriptionId, final String postId) {
    return new SubscribeCommand(subscriptionId, null, new PostSubscriptionRequest(postId));
  }
}
