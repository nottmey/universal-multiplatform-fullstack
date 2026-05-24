package social.example.eventbus;

import social.example.eventbus.grpc.Subscription;

public interface EventBusSubscription {

  Subscription.RequestCase subscriptionCase();

  AutoCloseable subscribe(EventBusSession session, Subscription subscription);
}
