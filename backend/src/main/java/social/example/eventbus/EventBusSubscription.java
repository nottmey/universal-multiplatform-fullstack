package social.example.eventbus;

import social.example.api.SubscribeCommand;

public interface EventBusSubscription {

  SubscriptionCase subscriptionCase();

  AutoCloseable subscribe(EventBusSession session, SubscribeCommand command);
}
