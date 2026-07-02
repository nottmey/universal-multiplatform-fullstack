package social.example.eventbus;

import social.example.api.ApiException;
import social.example.api.SubscribeCommand;

/** Which optional payload field of a {@link SubscribeCommand} is set, mirroring a proto oneof. */
public enum SubscriptionCase {
  TIMELINE,
  POST;

  public static SubscriptionCase fromCommand(final SubscribeCommand command) {
    SubscriptionCase subscriptionCase = null;
    if (command.timeline() != null) {
      subscriptionCase = TIMELINE;
    }
    if (command.post() != null) {
      if (subscriptionCase != null) {
        throw ApiException.invalidArgument("subscription oneof must have exactly one case");
      }
      subscriptionCase = POST;
    }
    if (subscriptionCase == null) {
      throw ApiException.invalidArgument("subscription oneof is required");
    }
    return subscriptionCase;
  }
}
