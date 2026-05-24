// This is a generated file - do not edit.
//
// Generated from posts.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use postDescriptor instead')
const Post$json = {
  '1': 'Post',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'body', '3': 2, '4': 1, '5': 9, '10': 'body'},
    {'1': 'posted_at_millis', '3': 3, '4': 1, '5': 3, '10': 'postedAtMillis'},
  ],
};

/// Descriptor for `Post`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List postDescriptor = $convert.base64Decode(
    'CgRQb3N0EhcKB3Bvc3RfaWQYASABKAlSBnBvc3RJZBISCgRib2R5GAIgASgJUgRib2R5EigKEH'
    'Bvc3RlZF9hdF9taWxsaXMYAyABKANSDnBvc3RlZEF0TWlsbGlz');

@$core.Deprecated('Use createPostRequestDescriptor instead')
const CreatePostRequest$json = {
  '1': 'CreatePostRequest',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 9, '10': 'body'},
  ],
};

/// Descriptor for `CreatePostRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPostRequestDescriptor = $convert
    .base64Decode('ChFDcmVhdGVQb3N0UmVxdWVzdBISCgRib2R5GAEgASgJUgRib2R5');

@$core.Deprecated('Use createPostResponseDescriptor instead')
const CreatePostResponse$json = {
  '1': 'CreatePostResponse',
  '2': [
    {
      '1': 'post',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.posts.grpc.Post',
      '10': 'post'
    },
  ],
};

/// Descriptor for `CreatePostResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPostResponseDescriptor = $convert.base64Decode(
    'ChJDcmVhdGVQb3N0UmVzcG9uc2USPAoEcG9zdBgBIAEoCzIoLnNvY2lhbC5leGFtcGxlLmZlYX'
    'R1cmVzLnBvc3RzLmdycGMuUG9zdFIEcG9zdA==');

@$core.Deprecated('Use editPostRequestDescriptor instead')
const EditPostRequest$json = {
  '1': 'EditPostRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'body', '3': 2, '4': 1, '5': 9, '10': 'body'},
  ],
};

/// Descriptor for `EditPostRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editPostRequestDescriptor = $convert.base64Decode(
    'Cg9FZGl0UG9zdFJlcXVlc3QSFwoHcG9zdF9pZBgBIAEoCVIGcG9zdElkEhIKBGJvZHkYAiABKA'
    'lSBGJvZHk=');

@$core.Deprecated('Use editPostResponseDescriptor instead')
const EditPostResponse$json = {
  '1': 'EditPostResponse',
  '2': [
    {
      '1': 'post',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.posts.grpc.Post',
      '10': 'post'
    },
  ],
};

/// Descriptor for `EditPostResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editPostResponseDescriptor = $convert.base64Decode(
    'ChBFZGl0UG9zdFJlc3BvbnNlEjwKBHBvc3QYASABKAsyKC5zb2NpYWwuZXhhbXBsZS5mZWF0dX'
    'Jlcy5wb3N0cy5ncnBjLlBvc3RSBHBvc3Q=');

@$core.Deprecated('Use deletePostRequestDescriptor instead')
const DeletePostRequest$json = {
  '1': 'DeletePostRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
  ],
};

/// Descriptor for `DeletePostRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePostRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVQb3N0UmVxdWVzdBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQ=');

@$core.Deprecated('Use deletePostResponseDescriptor instead')
const DeletePostResponse$json = {
  '1': 'DeletePostResponse',
};

/// Descriptor for `DeletePostResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePostResponseDescriptor =
    $convert.base64Decode('ChJEZWxldGVQb3N0UmVzcG9uc2U=');

@$core.Deprecated('Use subscribePostRequestDescriptor instead')
const SubscribePostRequest$json = {
  '1': 'SubscribePostRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
  ],
};

/// Descriptor for `SubscribePostRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribePostRequestDescriptor =
    $convert.base64Decode(
        'ChRTdWJzY3JpYmVQb3N0UmVxdWVzdBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQ=');

@$core.Deprecated('Use subscribePostResponseDescriptor instead')
const SubscribePostResponse$json = {
  '1': 'SubscribePostResponse',
  '2': [
    {
      '1': 'post',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.posts.grpc.Post',
      '10': 'post'
    },
  ],
};

/// Descriptor for `SubscribePostResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribePostResponseDescriptor = $convert.base64Decode(
    'ChVTdWJzY3JpYmVQb3N0UmVzcG9uc2USPAoEcG9zdBgBIAEoCzIoLnNvY2lhbC5leGFtcGxlLm'
    'ZlYXR1cmVzLnBvc3RzLmdycGMuUG9zdFIEcG9zdA==');
