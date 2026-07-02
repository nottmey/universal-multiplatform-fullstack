import 'dart:async';

import 'package:client/api.dart';
import 'package:frontend/event_bus/event_bus_socket.dart';

/// A controllable [EventBusSocket] for tests: push server messages, record
/// sent client frames, and end the socket with a close or error.
class FakeEventBusSocket implements EventBusSocket {
  FakeEventBusSocket()
    : _controller = StreamController<EventBusServerMessage>();

  final StreamController<EventBusServerMessage> _controller;
  final List<EventBusClientMessage> sentMessages = <EventBusClientMessage>[];
  bool closed = false;

  @override
  Stream<EventBusServerMessage> get messages => _controller.stream;

  @override
  void send(EventBusClientMessage message) => sentMessages.add(message);

  @override
  Future<void> close() async {
    closed = true;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void emit(EventBusServerMessage message) {
    if (!_controller.isClosed) {
      _controller.add(message);
    }
  }

  void emitConnectionReady() =>
      emit(const EventBusServerMessage(connectionReady: ConnectionReady()));

  void emitError(Object error) {
    if (!_controller.isClosed) {
      _controller.addError(error);
    }
  }

  void endStream() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
