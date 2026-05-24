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

import 'likes.pb.dart' as $4;
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
    $core.Iterable<Subscription>? subscriptions,
  }) {
    final result = create();
    if (context != null) result.context = context;
    if (subscriptions != null) result.subscriptions.addAll(subscriptions);
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
    ..pPM<Subscription>(2, _omitFieldNames ? '' : 'subscriptions',
        subBuilder: Subscription.create)
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

  @$pb.TagNumber(2)
  $pb.PbList<Subscription> get subscriptions => $_getList(1);
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

enum Subscription_Request { timeline, post, likes, notSet }

class Subscription extends $pb.GeneratedMessage {
  factory Subscription({
    $core.String? subscriptionId,
    $2.SubscribeTimelineRequest? timeline,
    $3.SubscribePostRequest? post,
    $4.SubscribeLikesRequest? likes,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (timeline != null) result.timeline = timeline;
    if (post != null) result.post = post;
    if (likes != null) result.likes = likes;
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
    2: Subscription_Request.timeline,
    3: Subscription_Request.post,
    4: Subscription_Request.likes,
    0: Subscription_Request.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Subscription',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOM<$2.SubscribeTimelineRequest>(2, _omitFieldNames ? '' : 'timeline',
        subBuilder: $2.SubscribeTimelineRequest.create)
    ..aOM<$3.SubscribePostRequest>(3, _omitFieldNames ? '' : 'post',
        subBuilder: $3.SubscribePostRequest.create)
    ..aOM<$4.SubscribeLikesRequest>(4, _omitFieldNames ? '' : 'likes',
        subBuilder: $4.SubscribeLikesRequest.create)
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

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  Subscription_Request whichRequest() =>
      _Subscription_RequestByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
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

  @$pb.TagNumber(2)
  $2.SubscribeTimelineRequest get timeline => $_getN(1);
  @$pb.TagNumber(2)
  set timeline($2.SubscribeTimelineRequest value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeline() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeline() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.SubscribeTimelineRequest ensureTimeline() => $_ensure(1);

  @$pb.TagNumber(3)
  $3.SubscribePostRequest get post => $_getN(2);
  @$pb.TagNumber(3)
  set post($3.SubscribePostRequest value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPost() => $_has(2);
  @$pb.TagNumber(3)
  void clearPost() => $_clearField(3);
  @$pb.TagNumber(3)
  $3.SubscribePostRequest ensurePost() => $_ensure(2);

  @$pb.TagNumber(4)
  $4.SubscribeLikesRequest get likes => $_getN(3);
  @$pb.TagNumber(4)
  set likes($4.SubscribeLikesRequest value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLikes() => $_has(3);
  @$pb.TagNumber(4)
  void clearLikes() => $_clearField(4);
  @$pb.TagNumber(4)
  $4.SubscribeLikesRequest ensureLikes() => $_ensure(3);
}

enum Event_Response { timeline, post, likes, notSet }

class Event extends $pb.GeneratedMessage {
  factory Event({
    $core.String? subscriptionId,
    $2.SubscribeTimelineResponse? timeline,
    $3.SubscribePostResponse? post,
    $4.SubscribeLikesResponse? likes,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (timeline != null) result.timeline = timeline;
    if (post != null) result.post = post;
    if (likes != null) result.likes = likes;
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
    2: Event_Response.timeline,
    3: Event_Response.post,
    4: Event_Response.likes,
    0: Event_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.eventbus.grpc'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOM<$2.SubscribeTimelineResponse>(2, _omitFieldNames ? '' : 'timeline',
        subBuilder: $2.SubscribeTimelineResponse.create)
    ..aOM<$3.SubscribePostResponse>(3, _omitFieldNames ? '' : 'post',
        subBuilder: $3.SubscribePostResponse.create)
    ..aOM<$4.SubscribeLikesResponse>(4, _omitFieldNames ? '' : 'likes',
        subBuilder: $4.SubscribeLikesResponse.create)
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
  $2.SubscribeTimelineResponse get timeline => $_getN(1);
  @$pb.TagNumber(2)
  set timeline($2.SubscribeTimelineResponse value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeline() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeline() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.SubscribeTimelineResponse ensureTimeline() => $_ensure(1);

  @$pb.TagNumber(3)
  $3.SubscribePostResponse get post => $_getN(2);
  @$pb.TagNumber(3)
  set post($3.SubscribePostResponse value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPost() => $_has(2);
  @$pb.TagNumber(3)
  void clearPost() => $_clearField(3);
  @$pb.TagNumber(3)
  $3.SubscribePostResponse ensurePost() => $_ensure(2);

  @$pb.TagNumber(4)
  $4.SubscribeLikesResponse get likes => $_getN(3);
  @$pb.TagNumber(4)
  set likes($4.SubscribeLikesResponse value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLikes() => $_has(3);
  @$pb.TagNumber(4)
  void clearLikes() => $_clearField(4);
  @$pb.TagNumber(4)
  $4.SubscribeLikesResponse ensureLikes() => $_ensure(3);
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
