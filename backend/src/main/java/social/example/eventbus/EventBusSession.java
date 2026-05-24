package social.example.eventbus;

import social.example.eventbus.grpc.Event;

public interface EventBusSession {

  void emit(Event event);
}
