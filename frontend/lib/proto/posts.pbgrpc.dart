// This is a generated file - do not edit.
//
// Generated from posts.proto.

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

import 'posts.pb.dart' as $0;

export 'posts.pb.dart';

@$pb.GrpcServiceName('social.example.features.posts.grpc.PostService')
class PostServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  PostServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.CreatePostResponse> createPost(
    $0.CreatePostRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createPost, request, options: options);
  }

  $grpc.ResponseFuture<$0.EditPostResponse> editPost(
    $0.EditPostRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$editPost, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeletePostResponse> deletePost(
    $0.DeletePostRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deletePost, request, options: options);
  }

  // method descriptors

  static final _$createPost =
      $grpc.ClientMethod<$0.CreatePostRequest, $0.CreatePostResponse>(
          '/social.example.features.posts.grpc.PostService/CreatePost',
          ($0.CreatePostRequest value) => value.writeToBuffer(),
          $0.CreatePostResponse.fromBuffer);
  static final _$editPost =
      $grpc.ClientMethod<$0.EditPostRequest, $0.EditPostResponse>(
          '/social.example.features.posts.grpc.PostService/EditPost',
          ($0.EditPostRequest value) => value.writeToBuffer(),
          $0.EditPostResponse.fromBuffer);
  static final _$deletePost =
      $grpc.ClientMethod<$0.DeletePostRequest, $0.DeletePostResponse>(
          '/social.example.features.posts.grpc.PostService/DeletePost',
          ($0.DeletePostRequest value) => value.writeToBuffer(),
          $0.DeletePostResponse.fromBuffer);
}

@$pb.GrpcServiceName('social.example.features.posts.grpc.PostService')
abstract class PostServiceBase extends $grpc.Service {
  $core.String get $name => 'social.example.features.posts.grpc.PostService';

  PostServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CreatePostRequest, $0.CreatePostResponse>(
        'CreatePost',
        createPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreatePostRequest.fromBuffer(value),
        ($0.CreatePostResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EditPostRequest, $0.EditPostResponse>(
        'EditPost',
        editPost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EditPostRequest.fromBuffer(value),
        ($0.EditPostResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeletePostRequest, $0.DeletePostResponse>(
        'DeletePost',
        deletePost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeletePostRequest.fromBuffer(value),
        ($0.DeletePostResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreatePostResponse> createPost_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreatePostRequest> $request) async {
    return createPost($call, await $request);
  }

  $async.Future<$0.CreatePostResponse> createPost(
      $grpc.ServiceCall call, $0.CreatePostRequest request);

  $async.Future<$0.EditPostResponse> editPost_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EditPostRequest> $request) async {
    return editPost($call, await $request);
  }

  $async.Future<$0.EditPostResponse> editPost(
      $grpc.ServiceCall call, $0.EditPostRequest request);

  $async.Future<$0.DeletePostResponse> deletePost_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeletePostRequest> $request) async {
    return deletePost($call, await $request);
  }

  $async.Future<$0.DeletePostResponse> deletePost(
      $grpc.ServiceCall call, $0.DeletePostRequest request);
}
