// This is a generated file - do not edit.
//
// Generated from likes.proto.

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

@$core.Deprecated('Use likeRequestDescriptor instead')
const LikeRequest$json = {
  '1': 'LikeRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
  ],
};

/// Descriptor for `LikeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List likeRequestDescriptor = $convert
    .base64Decode('CgtMaWtlUmVxdWVzdBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQ=');

@$core.Deprecated('Use likeResponseDescriptor instead')
const LikeResponse$json = {
  '1': 'LikeResponse',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'like_count', '3': 2, '4': 1, '5': 3, '10': 'likeCount'},
  ],
};

/// Descriptor for `LikeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List likeResponseDescriptor = $convert.base64Decode(
    'CgxMaWtlUmVzcG9uc2USFwoHcG9zdF9pZBgBIAEoCVIGcG9zdElkEh0KCmxpa2VfY291bnQYAi'
    'ABKANSCWxpa2VDb3VudA==');

@$core.Deprecated('Use subscribeLikesResponseDescriptor instead')
const SubscribeLikesResponse$json = {
  '1': 'SubscribeLikesResponse',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'like_count', '3': 2, '4': 1, '5': 3, '10': 'likeCount'},
  ],
};

/// Descriptor for `SubscribeLikesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeLikesResponseDescriptor =
    $convert.base64Decode(
        'ChZTdWJzY3JpYmVMaWtlc1Jlc3BvbnNlEhcKB3Bvc3RfaWQYASABKAlSBnBvc3RJZBIdCgpsaW'
        'tlX2NvdW50GAIgASgDUglsaWtlQ291bnQ=');

@$core.Deprecated('Use subscribeLikesRequestDescriptor instead')
const SubscribeLikesRequest$json = {
  '1': 'SubscribeLikesRequest',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
  ],
};

/// Descriptor for `SubscribeLikesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeLikesRequestDescriptor =
    $convert.base64Decode(
        'ChVTdWJzY3JpYmVMaWtlc1JlcXVlc3QSFwoHcG9zdF9pZBgBIAEoCVIGcG9zdElk');
