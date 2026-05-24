// This is a generated file - do not edit.
//
// Generated from likes.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LikeRequest extends $pb.GeneratedMessage {
  factory LikeRequest({
    $core.String? postId,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    return result;
  }

  LikeRequest._();

  factory LikeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LikeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LikeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.features.likes.grpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LikeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LikeRequest copyWith(void Function(LikeRequest) updates) =>
      super.copyWith((message) => updates(message as LikeRequest))
          as LikeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LikeRequest create() => LikeRequest._();
  @$core.override
  LikeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LikeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LikeRequest>(create);
  static LikeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);
}

class LikeResponse extends $pb.GeneratedMessage {
  factory LikeResponse({
    $core.String? postId,
    $fixnum.Int64? likeCount,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    if (likeCount != null) result.likeCount = likeCount;
    return result;
  }

  LikeResponse._();

  factory LikeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LikeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LikeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.features.likes.grpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aInt64(2, _omitFieldNames ? '' : 'likeCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LikeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LikeResponse copyWith(void Function(LikeResponse) updates) =>
      super.copyWith((message) => updates(message as LikeResponse))
          as LikeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LikeResponse create() => LikeResponse._();
  @$core.override
  LikeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LikeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LikeResponse>(create);
  static LikeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get likeCount => $_getI64(1);
  @$pb.TagNumber(2)
  set likeCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLikeCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearLikeCount() => $_clearField(2);
}

class SubscribeLikesResponse extends $pb.GeneratedMessage {
  factory SubscribeLikesResponse({
    $core.String? postId,
    $fixnum.Int64? likeCount,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    if (likeCount != null) result.likeCount = likeCount;
    return result;
  }

  SubscribeLikesResponse._();

  factory SubscribeLikesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeLikesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeLikesResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.features.likes.grpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aInt64(2, _omitFieldNames ? '' : 'likeCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeLikesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeLikesResponse copyWith(
          void Function(SubscribeLikesResponse) updates) =>
      super.copyWith((message) => updates(message as SubscribeLikesResponse))
          as SubscribeLikesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeLikesResponse create() => SubscribeLikesResponse._();
  @$core.override
  SubscribeLikesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeLikesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeLikesResponse>(create);
  static SubscribeLikesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get likeCount => $_getI64(1);
  @$pb.TagNumber(2)
  set likeCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLikeCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearLikeCount() => $_clearField(2);
}

class SubscribeLikesRequest extends $pb.GeneratedMessage {
  factory SubscribeLikesRequest({
    $core.String? postId,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    return result;
  }

  SubscribeLikesRequest._();

  factory SubscribeLikesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeLikesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeLikesRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'social.example.features.likes.grpc'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeLikesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeLikesRequest copyWith(
          void Function(SubscribeLikesRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeLikesRequest))
          as SubscribeLikesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeLikesRequest create() => SubscribeLikesRequest._();
  @$core.override
  SubscribeLikesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeLikesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeLikesRequest>(create);
  static SubscribeLikesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
