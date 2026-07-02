package social.example.eventbus;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.javalin.Javalin;
import io.javalin.openapi.HttpMethod;
import io.javalin.openapi.OpenApi;
import io.javalin.openapi.OpenApiContent;
import io.javalin.openapi.OpenApiParam;
import io.javalin.openapi.OpenApiRequestBody;
import io.javalin.openapi.OpenApiResponse;
import io.javalin.websocket.WsCloseContext;
import io.javalin.websocket.WsConnectContext;
import io.javalin.websocket.WsContext;
import io.javalin.websocket.WsErrorContext;
import io.javalin.websocket.WsMessageContext;
import java.util.EnumMap;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.api.ApiException;
import social.example.api.EventBusClientMessage;
import social.example.api.EventBusServerMessage;
import social.example.api.SubscribeCommand;
import social.example.utils.CloseQuietly;

@Log4j2
@RequiredArgsConstructor
public final class EventBusWebSocket {
  public static final String PATH = "/events";

  private static final String SESSION_ATTRIBUTE = "event-bus-session";

  private final EnumMap<SubscriptionCase, EventBusSubscription> subscriptionCases;
  private final ObjectMapper json;

  public static EventBusWebSocket fromSubscriptions(
      final List<EventBusSubscription> subscriptionCases, final ObjectMapper json) {
    val map = new EnumMap<SubscriptionCase, EventBusSubscription>(SubscriptionCase.class);
    for (val sub : subscriptionCases) {
      val replaced = map.put(sub.subscriptionCase(), sub);
      assert replaced == null : "subscriptions may not contain duplicate subscription cases";
    }
    return new EventBusWebSocket(map, json);
  }

  public void register(final Javalin app) {
    app.ws(
        PATH,
        ws -> {
          ws.onConnect(this::onConnect);
          ws.onMessage(this::onMessage);
          ws.onClose(this::onClose);
          ws.onError(this::onError);
        });
  }

  // Documentation-only operation: the endpoint is a WebSocket upgrade, but declaring the two
  // envelopes here makes them reachable from `paths`, which client generators require.
  @OpenApi(
      path = PATH,
      methods = HttpMethod.GET,
      operationId = "eventBus",
      summary = "EventBus WebSocket",
      description =
          "WebSocket endpoint (HTTP GET upgrade). The client sends EventBusClientMessage frames"
              + " (subscribe/unsubscribe) and receives EventBusServerMessage frames"
              + " (connectionReady handshake, subscription events, subscription errors).",
      tags = "events",
      queryParams =
          @OpenApiParam(
              name = "token",
              required = true,
              description =
                  "Firebase ID token; WebSocket clients cannot send an Authorization"
                      + " header from browsers."),
      requestBody =
          @OpenApiRequestBody(
              description = "Message frames the client sends over the socket; not an HTTP body.",
              content = @OpenApiContent(from = EventBusClientMessage.class)),
      responses =
          @OpenApiResponse(
              status = "200",
              description = "Message frames the server pushes over the socket.",
              content = @OpenApiContent(from = EventBusServerMessage.class)))
  private void onConnect(final WsConnectContext ctx) {
    ctx.enableAutomaticPings();
    val session = new ConnectionSession(ctx, json);
    ctx.attribute(SESSION_ATTRIBUTE, session);
    log.debug("event bus connected: {}", ctx.sessionId());
    session.emit(EventBusServerMessage.ready());
  }

  private void onMessage(final WsMessageContext ctx) {
    val session = session(ctx);
    final EventBusClientMessage message;
    try {
      message = json.readValue(ctx.message(), EventBusClientMessage.class);
    } catch (final Exception e) {
      log.warn("event bus: unparseable client message", e);
      session.emit(
          EventBusServerMessage.error(
              null, ApiException.invalidArgument("unparseable client message").toError()));
      return;
    }
    if (message.subscribe() != null) {
      subscribe(session, message.subscribe());
    } else if (message.unsubscribe() != null) {
      val id = message.unsubscribe().subscriptionId();
      if (id != null && !id.isBlank()) {
        session.removeSubscription(id);
      }
    } else {
      session.emit(
          EventBusServerMessage.error(
              null, ApiException.invalidArgument("client message oneof is required").toError()));
    }
  }

  private void subscribe(final ConnectionSession session, final SubscribeCommand command) {
    val id = command.subscriptionId();
    try {
      if (id == null || id.isBlank()) {
        throw ApiException.invalidArgument("subscription_id is required");
      }
      val subscriptionCase = SubscriptionCase.fromCommand(command);
      val handler = subscriptionCases.get(subscriptionCase);
      if (handler == null) {
        throw ApiException.unimplemented("no subscription handler for case: " + subscriptionCase);
      }
      session.addSubscription(id, handler.subscribe(session, command));
    } catch (final ApiException e) {
      log.warn("subscribe: rejected", e);
      session.emit(EventBusServerMessage.error(id, e.toError()));
    }
  }

  private void onClose(final WsCloseContext ctx) {
    log.debug("event bus closed: {}", ctx.sessionId());
    session(ctx).closeAll();
  }

  private void onError(final WsErrorContext ctx) {
    log.warn("event bus error: {}", ctx.sessionId(), ctx.error());
    session(ctx).closeAll();
  }

  private static ConnectionSession session(final WsContext ctx) {
    val session = (ConnectionSession) ctx.attribute(SESSION_ATTRIBUTE);
    assert session != null : "event bus session must be attached on connect";
    return session;
  }

  @RequiredArgsConstructor(access = AccessLevel.PACKAGE)
  private static class ConnectionSession implements EventBusSession {
    private final WsContext ctx;
    private final ObjectMapper json;
    private final ConcurrentHashMap<String, AutoCloseable> activeSubscriptions =
        new ConcurrentHashMap<>();

    // Rama proxy callbacks emit from their own threads; Jetty remote endpoints are not safe for
    // concurrent sends.
    @Override
    public synchronized void emit(final EventBusServerMessage event) {
      if (!ctx.session.isOpen()) {
        return;
      }
      try {
        ctx.send(json.writeValueAsString(event));
      } catch (final Exception e) {
        log.debug("event bus: send failed on closing socket", e);
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
