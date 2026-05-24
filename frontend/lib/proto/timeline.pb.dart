// This is a generated file - do not edit.
//
// Generated from timeline.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SubscribeTimelineRequest extends $pb.GeneratedMessage {
  factory SubscribeTimelineRequest() => create();

  SubscribeTimelineRequest._();

  factory SubscribeTimelineRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeTimelineRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeTimelineRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.features.timeline.grpc'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeTimelineRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeTimelineRequest copyWith(
          void Function(SubscribeTimelineRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeTimelineRequest))
          as SubscribeTimelineRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeTimelineRequest create() => SubscribeTimelineRequest._();
  @$core.override
  SubscribeTimelineRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeTimelineRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeTimelineRequest>(create);
  static SubscribeTimelineRequest? _defaultInstance;
}

class SubscribeTimelineResponse extends $pb.GeneratedMessage {
  factory SubscribeTimelineResponse({
    $core.Iterable<$core.String>? postIds,
  }) {
    final result = create();
    if (postIds != null) result.postIds.addAll(postIds);
    return result;
  }

  SubscribeTimelineResponse._();

  factory SubscribeTimelineResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeTimelineResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeTimelineResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.features.timeline.grpc'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'postIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeTimelineResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeTimelineResponse copyWith(
          void Function(SubscribeTimelineResponse) updates) =>
      super.copyWith((message) => updates(message as SubscribeTimelineResponse))
          as SubscribeTimelineResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeTimelineResponse create() => SubscribeTimelineResponse._();
  @$core.override
  SubscribeTimelineResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeTimelineResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeTimelineResponse>(create);
  static SubscribeTimelineResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get postIds => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
