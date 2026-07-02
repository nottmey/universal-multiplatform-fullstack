import 'dart:async';
import 'dart:convert';

import 'package:client/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A thin, app-owned view of the EventBus WebSocket. Small enough to fake in
/// tests without reaching into [WebSocketChannel] internals — the direct
/// analogue of the old mocked gRPC client.
abstract interface class EventBusSocket {
  /// Decoded server messages. Errors/close surface as stream error/done.
  Stream<EventBusServerMessage> get messages;

  void send(EventBusClientMessage message);

  Future<void> close();
}

/// Opens an [EventBusSocket] for the given uri. Completes once the socket is
/// connected (or throws if the connection cannot be established).
typedef EventBusConnector = Future<EventBusSocket> Function(Uri uri);

/// Overridden in tests to inject a fake socket.
final eventBusConnectorProvider = Provider<EventBusConnector>(
  (ref) => _connectWebSocket,
);

Future<EventBusSocket> _connectWebSocket(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return _WebSocketChannelSocket(channel);
}

class _WebSocketChannelSocket implements EventBusSocket {
  _WebSocketChannelSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<EventBusServerMessage> get messages => _channel.stream.map(
    (frame) => EventBusServerMessage.fromJson(
      jsonDecode(frame as String) as Map<String, dynamic>,
    ),
  );

  @override
  void send(EventBusClientMessage message) {
    _channel.sink.add(jsonEncode(message.toJson()));
  }

  @override
  Future<void> close() => _channel.sink.close();
}
