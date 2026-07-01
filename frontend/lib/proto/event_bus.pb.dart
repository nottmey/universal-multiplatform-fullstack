// This is a generated file - do not edit.
//
// Generated from event_bus.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'posts.pb.dart' as $3;
import 'timeline.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ConnectionContext extends $pb.GeneratedMessage {
  factory ConnectionContext({
    $core.String? id,
    $fixnum.Int64? epoch,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (epoch != null) result.epoch = epoch;
    return result;
  }

  ConnectionContext._();

  factory ConnectionContext.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectionContext.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionContext',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'epoch')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionContext clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionContext copyWith(void Function(ConnectionContext) updates) =>
      super.copyWith((message) => updates(message as ConnectionContext))
          as ConnectionContext;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectionContext create() => ConnectionContext._();
  @$core.override
  ConnectionContext createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectionContext getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionContext>(create);
  static ConnectionContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get epoch => $_getI64(1);
  @$pb.TagNumber(2)
  set epoch($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpoch() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpoch() => $_clearField(2);
}

class EventBusRequest extends $pb.GeneratedMessage {
  factory EventBusRequest({
    ConnectionContext? context,
  }) {
    final result = create();
    if (context != null) result.context = context;
    return result;
  }

  EventBusRequest._();

  factory EventBusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventBusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventBusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..aOM<ConnectionContext>(1, _omitFieldNames ? '' : 'context',
        subBuilder: ConnectionContext.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventBusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventBusRequest copyWith(void Function(EventBusRequest) updates) =>
      super.copyWith((message) => updates(message as EventBusRequest))
          as EventBusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventBusRequest create() => EventBusRequest._();
  @$core.override
  EventBusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventBusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventBusRequest>(create);
  static EventBusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionContext get context => $_getN(0);
  @$pb.TagNumber(1)
  set context(ConnectionContext value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearContext() => $_clearField(1);
  @$pb.TagNumber(1)
  ConnectionContext ensureContext() => $_ensure(0);
}

class SubscribeRequest extends $pb.GeneratedMessage {
  factory SubscribeRequest({
    ConnectionContext? context,
    Subscription? subscription,
  }) {
    final result = create();
    if (context != null) result.context = context;
    if (subscription != null) result.subscription = subscription;
    return result;
  }

  SubscribeRequest._();

  factory SubscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..aOM<ConnectionContext>(1, _omitFieldNames ? '' : 'context',
        subBuilder: ConnectionContext.create)
    ..aOM<Subscription>(2, _omitFieldNames ? '' : 'subscription',
        subBuilder: Subscription.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest copyWith(void Function(SubscribeRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeRequest))
          as SubscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeRequest create() => SubscribeRequest._();
  @$core.override
  SubscribeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeRequest>(create);
  static SubscribeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionContext get context => $_getN(0);
  @$pb.TagNumber(1)
  set context(ConnectionContext value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearContext() => $_clearField(1);
  @$pb.TagNumber(1)
  ConnectionContext ensureContext() => $_ensure(0);

  @$pb.TagNumber(2)
  Subscription get subscription => $_getN(1);
  @$pb.TagNumber(2)
  set subscription(Subscription value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscription() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscription() => $_clearField(2);
  @$pb.TagNumber(2)
  Subscription ensureSubscription() => $_ensure(1);
}

enum Subscription_Request { timeline, post, notSet }

class Subscription extends $pb.GeneratedMessage {
  factory Subscription({
    $core.String? subscriptionId,
    $2.SubscribeTimelineRequest? timeline,
    $3.SubscribePostRequest? post,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (timeline != null) result.timeline = timeline;
    if (post != null) result.post = post;
    return result;
  }

  Subscription._();

  factory Subscription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Subscription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Subscription_Request>
      _Subscription_RequestByTag = {
    3: Subscription_Request.timeline,
    4: Subscription_Request.post,
    0: Subscription_Request.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Subscription',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..oo(0, [3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOM<$2.SubscribeTimelineRequest>(3, _omitFieldNames ? '' : 'timeline',
        subBuilder: $2.SubscribeTimelineRequest.create)
    ..aOM<$3.SubscribePostRequest>(4, _omitFieldNames ? '' : 'post',
        subBuilder: $3.SubscribePostRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscription clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscription copyWith(void Function(Subscription) updates) =>
      super.copyWith((message) => updates(message as Subscription))
          as Subscription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Subscription create() => Subscription._();
  @$core.override
  Subscription createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Subscription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Subscription>(create);
  static Subscription? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  Subscription_Request whichRequest() =>
      _Subscription_RequestByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearRequest() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get subscriptionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscriptionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscriptionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscriptionId() => $_clearField(1);

  /// skipping 2, to align numbering with Event.response
  @$pb.TagNumber(3)
  $2.SubscribeTimelineRequest get timeline => $_getN(1);
  @$pb.TagNumber(3)
  set timeline($2.SubscribeTimelineRequest value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeline() => $_has(1);
  @$pb.TagNumber(3)
  void clearTimeline() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.SubscribeTimelineRequest ensureTimeline() => $_ensure(1);

  @$pb.TagNumber(4)
  $3.SubscribePostRequest get post => $_getN(2);
  @$pb.TagNumber(4)
  set post($3.SubscribePostRequest value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPost() => $_has(2);
  @$pb.TagNumber(4)
  void clearPost() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.SubscribePostRequest ensurePost() => $_ensure(2);
}

/// Emitted once when the server has registered the EventBus session.
class ConnectionReady extends $pb.GeneratedMessage {
  factory ConnectionReady() => create();

  ConnectionReady._();

  factory ConnectionReady.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectionReady.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionReady',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionReady clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionReady copyWith(void Function(ConnectionReady) updates) =>
      super.copyWith((message) => updates(message as ConnectionReady))
          as ConnectionReady;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectionReady create() => ConnectionReady._();
  @$core.override
  ConnectionReady createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectionReady getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionReady>(create);
  static ConnectionReady? _defaultInstance;
}

enum Event_Response { connectionReady, timeline, post, notSet }

class Event extends $pb.GeneratedMessage {
  factory Event({
    $core.String? subscriptionId,
    ConnectionReady? connectionReady,
    $2.SubscribeTimelineResponse? timeline,
    $3.SubscribePostResponse? post,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (connectionReady != null) result.connectionReady = connectionReady;
    if (timeline != null) result.timeline = timeline;
    if (post != null) result.post = post;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Event_Response> _Event_ResponseByTag = {
    2: Event_Response.connectionReady,
    3: Event_Response.timeline,
    4: Event_Response.post,
    0: Event_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOM<ConnectionReady>(2, _omitFieldNames ? '' : 'connectionReady',
        subBuilder: ConnectionReady.create)
    ..aOM<$2.SubscribeTimelineResponse>(3, _omitFieldNames ? '' : 'timeline',
        subBuilder: $2.SubscribeTimelineResponse.create)
    ..aOM<$3.SubscribePostResponse>(4, _omitFieldNames ? '' : 'post',
        subBuilder: $3.SubscribePostResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Event create() => Event._();
  @$core.override
  Event createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Event>(create);
  static Event? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  Event_Response whichResponse() => _Event_ResponseByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearResponse() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get subscriptionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscriptionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscriptionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscriptionId() => $_clearField(1);

  @$pb.TagNumber(2)
  ConnectionReady get connectionReady => $_getN(1);
  @$pb.TagNumber(2)
  set connectionReady(ConnectionReady value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectionReady() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectionReady() => $_clearField(2);
  @$pb.TagNumber(2)
  ConnectionReady ensureConnectionReady() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.SubscribeTimelineResponse get timeline => $_getN(2);
  @$pb.TagNumber(3)
  set timeline($2.SubscribeTimelineResponse value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeline() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeline() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.SubscribeTimelineResponse ensureTimeline() => $_ensure(2);

  @$pb.TagNumber(4)
  $3.SubscribePostResponse get post => $_getN(3);
  @$pb.TagNumber(4)
  set post($3.SubscribePostResponse value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPost() => $_has(3);
  @$pb.TagNumber(4)
  void clearPost() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.SubscribePostResponse ensurePost() => $_ensure(3);
}

class UnsubscribeRequest extends $pb.GeneratedMessage {
  factory UnsubscribeRequest({
    ConnectionContext? context,
    $core.String? subscriptionId,
  }) {
    final result = create();
    if (context != null) result.context = context;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    return result;
  }

  UnsubscribeRequest._();

  factory UnsubscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnsubscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnsubscribeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..aOM<ConnectionContext>(1, _omitFieldNames ? '' : 'context',
        subBuilder: ConnectionContext.create)
    ..aOS(2, _omitFieldNames ? '' : 'subscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnsubscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnsubscribeRequest copyWith(void Function(UnsubscribeRequest) updates) =>
      super.copyWith((message) => updates(message as UnsubscribeRequest))
          as UnsubscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnsubscribeRequest create() => UnsubscribeRequest._();
  @$core.override
  UnsubscribeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnsubscribeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnsubscribeRequest>(create);
  static UnsubscribeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionContext get context => $_getN(0);
  @$pb.TagNumber(1)
  set context(ConnectionContext value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearContext() => $_clearField(1);
  @$pb.TagNumber(1)
  ConnectionContext ensureContext() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get subscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscriptionId() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
