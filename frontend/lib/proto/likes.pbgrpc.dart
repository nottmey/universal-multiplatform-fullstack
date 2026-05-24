// This is a generated file - do not edit.
//
// Generated from likes.proto.

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

import 'likes.pb.dart' as $0;

export 'likes.pb.dart';

@$pb.GrpcServiceName('social.example.features.likes.grpc.LikesService')
class LikesServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LikesServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.LikeResponse> like(
    $0.LikeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$like, request, options: options);
  }

  // method descriptors

  static final _$like = $grpc.ClientMethod<$0.LikeRequest, $0.LikeResponse>(
      '/social.example.features.likes.grpc.LikesService/Like',
      ($0.LikeRequest value) => value.writeToBuffer(),
      $0.LikeResponse.fromBuffer);
}

@$pb.GrpcServiceName('social.example.features.likes.grpc.LikesService')
abstract class LikesServiceBase extends $grpc.Service {
  $core.String get $name => 'social.example.features.likes.grpc.LikesService';

  LikesServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LikeRequest, $0.LikeResponse>(
        'Like',
        like_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LikeRequest.fromBuffer(value),
        ($0.LikeResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.LikeResponse> like_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LikeRequest> $request) async {
    return like($call, await $request);
  }

  $async.Future<$0.LikeResponse> like(
      $grpc.ServiceCall call, $0.LikeRequest request);
}
