// This is a generated file - do not edit.
//
// Generated from event_bus.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'event_bus.pb.dart' as $0;

export 'event_bus.pb.dart';

@$pb.GrpcServiceName('social.example.eventbus.grpc.EventBusService')
class EventBusServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EventBusServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$0.Event> eventBus(
    $0.EventBusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$eventBus, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$1.Empty> subscribe(
    $0.SubscribeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$subscribe, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> unsubscribe(
    $0.UnsubscribeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unsubscribe, request, options: options);
  }

  // method descriptors

  static final _$eventBus = $grpc.ClientMethod<$0.EventBusRequest, $0.Event>(
      '/social.example.eventbus.grpc.EventBusService/EventBus',
      ($0.EventBusRequest value) => value.writeToBuffer(),
      $0.Event.fromBuffer);
  static final _$subscribe = $grpc.ClientMethod<$0.SubscribeRequest, $1.Empty>(
      '/social.example.eventbus.grpc.EventBusService/Subscribe',
      ($0.SubscribeRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$unsubscribe =
      $grpc.ClientMethod<$0.UnsubscribeRequest, $1.Empty>(
          '/social.example.eventbus.grpc.EventBusService/Unsubscribe',
          ($0.UnsubscribeRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
}

@$pb.GrpcServiceName('social.example.eventbus.grpc.EventBusService')
abstract class EventBusServiceBase extends $grpc.Service {
  $core.String get $name => 'social.example.eventbus.grpc.EventBusService';

  EventBusServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.EventBusRequest, $0.Event>(
        'EventBus',
        eventBus_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.EventBusRequest.fromBuffer(value),
        ($0.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SubscribeRequest, $1.Empty>(
        'Subscribe',
        subscribe_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SubscribeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UnsubscribeRequest, $1.Empty>(
        'Unsubscribe',
        unsubscribe_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UnsubscribeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
  }

  $async.Stream<$0.Event> eventBus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EventBusRequest> $request) async* {
    yield* eventBus($call, await $request);
  }

  $async.Stream<$0.Event> eventBus(
      $grpc.ServiceCall call, $0.EventBusRequest request);

  $async.Future<$1.Empty> subscribe_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SubscribeRequest> $request) async {
    return subscribe($call, await $request);
  }

  $async.Future<$1.Empty> subscribe(
      $grpc.ServiceCall call, $0.SubscribeRequest request);

  $async.Future<$1.Empty> unsubscribe_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UnsubscribeRequest> $request) async {
    return unsubscribe($call, await $request);
  }

  $async.Future<$1.Empty> unsubscribe(
      $grpc.ServiceCall call, $0.UnsubscribeRequest request);
}
