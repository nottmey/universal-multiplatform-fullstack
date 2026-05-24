package social.example.eventbus;

import com.google.protobuf.Empty;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.ServerCallStreamObserver;
import io.grpc.stub.StreamObserver;
import java.util.EnumMap;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.eventbus.grpc.ConnectionContext;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.EventBusRequest;
import social.example.eventbus.grpc.EventBusServiceGrpc;
import social.example.eventbus.grpc.SubscribeRequest;
import social.example.eventbus.grpc.Subscription;
import social.example.eventbus.grpc.UnsubscribeRequest;
import social.example.utils.CloseQuietly;

@Log4j2
@RequiredArgsConstructor
public class EventBusService extends EventBusServiceGrpc.EventBusServiceImplBase {
  private final EnumMap<Subscription.RequestCase, EventBusSubscription> subscriptionCases;

  private final ConcurrentHashMap<ConnectionContext, InternalEventBusSession> activeSessions =
      new ConcurrentHashMap<>();

  public static EventBusService fromSubscriptions(
      final List<EventBusSubscription> subscriptionCases) {
    val map =
        new EnumMap<Subscription.RequestCase, EventBusSubscription>(Subscription.RequestCase.class);
    for (val sub : subscriptionCases) {
      val replaced = map.put(sub.subscriptionCase(), sub);
      assert replaced == null : "subscriptionServices may not contain duplicate subscription cases";
    }
    assert !map.containsKey(Subscription.RequestCase.REQUEST_NOT_SET)
        : "REQUEST_NOT_SET is not a valid subscription case";
    return new EventBusService(map);
  }

  @Override
  public void eventBus(final EventBusRequest request, final StreamObserver<Event> response) {
    val stream = (ServerCallStreamObserver<Event>) response;
    try {
      val connectionContext = validateConnectionContext(request.getContext());
      closeOlderEpochs(connectionContext);
      val session = new InternalEventBusSession(stream);
      val replaced = activeSessions.put(connectionContext, session);
      if (replaced != null) {
        replaced.closeAll();
      }
      stream.setOnCancelHandler(
          () -> {
            activeSessions.remove(connectionContext, session);
            session.closeAll();
          });
      try {
        for (val subscription : request.getSubscriptionsList()) {
          startSubscription(session, subscription);
        }
      } catch (final StatusRuntimeException e) {
        log.warn("eventBus: subscription setup failed", e);
        activeSessions.remove(connectionContext, session);
        session.closeAll();
        if (!stream.isCancelled()) {
          stream.onError(e);
        }
      }
    } catch (final StatusRuntimeException e) {
      log.warn("eventBus: connection setup failed", e);
      if (!stream.isCancelled()) {
        stream.onError(e);
      }
    }
  }

  @Override
  public void subscribe(final SubscribeRequest request, final StreamObserver<Empty> response) {
    try {
      val connectionContext = validateConnectionContext(request.getContext());
      val busSession = activeSessions.get(connectionContext);
      if (busSession == null) {
        response.onError(
            Status.FAILED_PRECONDITION
                .withDescription("no active EventBus stream for this session and epoch")
                .asRuntimeException());
        return;
      }
      startSubscription(busSession, request.getSubscription());
      response.onNext(Empty.getDefaultInstance());
      response.onCompleted();
    } catch (final StatusRuntimeException e) {
      log.warn("subscribe: gRPC failure", e);
      response.onError(e);
    }
  }

  @Override
  public void unsubscribe(final UnsubscribeRequest request, final StreamObserver<Empty> response) {
    val id = request.getSubscriptionId();
    val connectionContext = validateConnectionContext(request.getContext());
    val session = activeSessions.get(connectionContext);
    if (session != null && !id.isBlank()) {
      session.removeSubscription(id);
    }
    response.onNext(Empty.getDefaultInstance());
    response.onCompleted();
  }

  private void closeOlderEpochs(final ConnectionContext context) {
    val sessionId = context.getId();
    val epoch = context.getEpoch();
    for (val other : activeSessions.keySet()) {
      if (other.getId().equals(sessionId) && other.getEpoch() < epoch) {
        val previousSession = activeSessions.remove(other);
        if (previousSession != null) {
          previousSession.closeAll();
        }
      }
    }
  }

  private void startSubscription(
      final InternalEventBusSession session, final Subscription subscription) {
    val id = subscription.getSubscriptionId();
    if (id.isBlank()) {
      throw Status.INVALID_ARGUMENT
          .withDescription("subscription_id is required")
          .asRuntimeException();
    }
    val subscriptionCase = subscription.getRequestCase();
    if (subscriptionCase == Subscription.RequestCase.REQUEST_NOT_SET) {
      throw Status.INVALID_ARGUMENT
          .withDescription("subscription oneof is required")
          .asRuntimeException();
    }
    val handler = subscriptionCases.get(subscriptionCase);
    if (handler == null) {
      throw Status.UNIMPLEMENTED
          .withDescription("no subscription handler for case: " + subscriptionCase)
          .asRuntimeException();
    }
    session.addSubscription(id, handler.subscribe(session, subscription));
  }

  private static ConnectionContext validateConnectionContext(final ConnectionContext context) {
    val id = context.getId();
    if (id.isBlank()) {
      throw Status.INVALID_ARGUMENT
          .withDescription("connection context id is required")
          .asRuntimeException();
    }
    if (context.getEpoch() < 0) {
      throw Status.INVALID_ARGUMENT
          .withDescription("connection context epoch must be non-negative")
          .asRuntimeException();
    }
    return context;
  }

  @RequiredArgsConstructor(access = AccessLevel.PACKAGE)
  private static class InternalEventBusSession implements EventBusSession {
    private final ServerCallStreamObserver<Event> stream;
    private final ConcurrentHashMap<String, AutoCloseable> activeSubscriptions =
        new ConcurrentHashMap<>();

    @Override
    public void emit(final Event event) {
      if (!stream.isCancelled()) {
        stream.onNext(event);
      }
    }

    void addSubscription(final String id, final AutoCloseable handle) {
      val previous = activeSubscriptions.put(id, handle);
      CloseQuietly.close(previous);
    }

    void removeSubscription(final String id) {
      val previous = activeSubscriptions.remove(id);
      CloseQuietly.close(previous);
    }

    void closeAll() {
      activeSubscriptions.forEach((id, subscription) -> CloseQuietly.close(subscription));
      activeSubscriptions.clear();
    }
  }
}
