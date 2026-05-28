import 'dart:async';

import 'fake_event_bus_response_stream.dart';
import 'recording_lifecycle_event.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import '../../fixtures/immediate_unary_response_future.dart';
import '../../mock_definitions.mocks.dart';
import 'package:mockito/mockito.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

MockEventBusServiceClient setupRecordingEventBusClient({
  List<RecordingLifecycleEvent>? lifecycleTimeline,
  List<EventBusRequest>? eventBusRequests,
  List<SubscribeRequest>? subscribeCalls,
  List<UnsubscribeRequest>? unsubscribeCalls,
  void Function(StreamController<Event> busController)? onEventBusStream,
  bool deferConnectionReady = false,
  Future<Empty> Function(SubscribeRequest request)? subscribeResponse,
}) {
  final client = MockEventBusServiceClient();

  when(client.eventBus(any, options: anyNamed('options'))).thenAnswer((
    invocation,
  ) {
    lifecycleTimeline?.add(OpenedBus());
    eventBusRequests?.add(
      invocation.positionalArguments.first as EventBusRequest,
    );
    final busController = StreamController<Event>();
    if (!deferConnectionReady) {
      busController.add(Event(connectionReady: ConnectionReady()));
    }
    onEventBusStream?.call(busController);
    return FakeEventBusResponseStream(
      busController.stream,
      onCancel: () => lifecycleTimeline?.add(ClosedBus()),
    );
  });

  when(client.subscribe(any, options: anyNamed('options'))).thenAnswer((
    invocation,
  ) {
    lifecycleTimeline?.add(Subscribed());
    final request = invocation.positionalArguments.first as SubscribeRequest;
    subscribeCalls?.add(request);
    final response =
        subscribeResponse?.call(request) ?? Future<Empty>.value(Empty());
    return ImmediateUnaryResponseFuture(response);
  });

  when(client.unsubscribe(any, options: anyNamed('options'))).thenAnswer((
    invocation,
  ) {
    lifecycleTimeline?.add(Unsubscribed());
    unsubscribeCalls?.add(
      invocation.positionalArguments.first as UnsubscribeRequest,
    );
    return ImmediateUnaryResponseFuture(Future<Empty>.value(Empty()));
  });

  return client;
}
