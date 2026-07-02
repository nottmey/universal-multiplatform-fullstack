import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:client/api_client.dart';
import 'package:client/api_exception.dart';
import 'package:client/models/event_bus_client_message.dart';
import 'package:client/models/event_bus_server_message.dart';

/// Endpoints with tag events
class EventsApi {
  EventsApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  /// EventBus WebSocket
  /// WebSocket endpoint (HTTP GET upgrade). The client sends
  /// EventBusClientMessage frames (subscribe/unsubscribe) and receives
  /// EventBusServerMessage frames (connectionReady handshake, subscription
  /// events, subscription errors).
  Future<EventBusServerMessage> eventBus(
    String token, {
    EventBusClientMessage? eventBusClientMessage,
  }) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/events',
      queryParameters: {
        'token': [token],
      },
      body: eventBusClientMessage?.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException<Object?>(
        response.statusCode,
        response.body,
      );
    }

    if (response.body.isNotEmpty) {
      return EventBusServerMessage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException<Object?>.unhandled(response.statusCode);
  }
}
