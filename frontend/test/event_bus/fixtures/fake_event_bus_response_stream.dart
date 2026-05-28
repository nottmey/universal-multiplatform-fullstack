import 'dart:async';

import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:grpc/grpc.dart';

final class FakeEventBusResponseStream extends StreamView<Event>
    implements ResponseStream<Event> {
  FakeEventBusResponseStream(
    super.stream, {
    Future<Map<String, String>>? headersFuture,
    this.onCancel,
  }) : _headersFuture =
           headersFuture ??
           Future<Map<String, String>>.value(<String, String>{});

  final Future<Map<String, String>> _headersFuture;
  final void Function()? onCancel;

  @override
  Future<Map<String, String>> get headers => _headersFuture;

  @override
  Future<Map<String, String>> get trailers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<void> cancel() async {
    onCancel?.call();
  }

  @override
  ResponseFuture<Event> get single =>
      throw UnsupportedError('FakeEventBusResponseStream.single');
}
