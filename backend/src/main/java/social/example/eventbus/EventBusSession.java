package social.example.eventbus;

import social.example.api.EventBusServerMessage;

public interface EventBusSession {

  void emit(EventBusServerMessage event);
}
