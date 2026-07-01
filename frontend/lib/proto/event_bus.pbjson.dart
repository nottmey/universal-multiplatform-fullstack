// This is a generated file - do not edit.
//
// Generated from event_bus.proto.

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

@$core.Deprecated('Use connectionContextDescriptor instead')
const ConnectionContext$json = {
  '1': 'ConnectionContext',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'epoch', '3': 2, '4': 1, '5': 3, '10': 'epoch'},
  ],
};

/// Descriptor for `ConnectionContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionContextDescriptor = $convert.base64Decode(
    'ChFDb25uZWN0aW9uQ29udGV4dBIOCgJpZBgBIAEoCVICaWQSFAoFZXBvY2gYAiABKANSBWVwb2'
    'No');

@$core.Deprecated('Use eventBusRequestDescriptor instead')
const EventBusRequest$json = {
  '1': 'EventBusRequest',
  '2': [
    {
      '1': 'context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.social.example.eventbus.grpc.ConnectionContext',
      '10': 'context'
    },
  ],
};

/// Descriptor for `EventBusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventBusRequestDescriptor = $convert.base64Decode(
    'Cg9FdmVudEJ1c1JlcXVlc3QSSQoHY29udGV4dBgBIAEoCzIvLnNvY2lhbC5leGFtcGxlLmV2ZW'
    '50YnVzLmdycGMuQ29ubmVjdGlvbkNvbnRleHRSB2NvbnRleHQ=');

@$core.Deprecated('Use subscribeRequestDescriptor instead')
const SubscribeRequest$json = {
  '1': 'SubscribeRequest',
  '2': [
    {
      '1': 'context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.social.example.eventbus.grpc.ConnectionContext',
      '10': 'context'
    },
    {
      '1': 'subscription',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.social.example.eventbus.grpc.Subscription',
      '10': 'subscription'
    },
  ],
};

/// Descriptor for `SubscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeRequestDescriptor = $convert.base64Decode(
    'ChBTdWJzY3JpYmVSZXF1ZXN0EkkKB2NvbnRleHQYASABKAsyLy5zb2NpYWwuZXhhbXBsZS5ldm'
    'VudGJ1cy5ncnBjLkNvbm5lY3Rpb25Db250ZXh0Ugdjb250ZXh0Ek4KDHN1YnNjcmlwdGlvbhgC'
    'IAEoCzIqLnNvY2lhbC5leGFtcGxlLmV2ZW50YnVzLmdycGMuU3Vic2NyaXB0aW9uUgxzdWJzY3'
    'JpcHRpb24=');

@$core.Deprecated('Use subscriptionDescriptor instead')
const Subscription$json = {
  '1': 'Subscription',
  '2': [
    {'1': 'subscription_id', '3': 1, '4': 1, '5': 9, '10': 'subscriptionId'},
    {
      '1': 'timeline',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.timeline.grpc.SubscribeTimelineRequest',
      '9': 0,
      '10': 'timeline'
    },
    {
      '1': 'post',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.posts.grpc.SubscribePostRequest',
      '9': 0,
      '10': 'post'
    },
  ],
  '8': [
    {'1': 'request'},
  ],
};

/// Descriptor for `Subscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionDescriptor = $convert.base64Decode(
    'CgxTdWJzY3JpcHRpb24SJwoPc3Vic2NyaXB0aW9uX2lkGAEgASgJUg5zdWJzY3JpcHRpb25JZB'
    'JdCgh0aW1lbGluZRgDIAEoCzI/LnNvY2lhbC5leGFtcGxlLmZlYXR1cmVzLnRpbWVsaW5lLmdy'
    'cGMuU3Vic2NyaWJlVGltZWxpbmVSZXF1ZXN0SABSCHRpbWVsaW5lEk4KBHBvc3QYBCABKAsyOC'
    '5zb2NpYWwuZXhhbXBsZS5mZWF0dXJlcy5wb3N0cy5ncnBjLlN1YnNjcmliZVBvc3RSZXF1ZXN0'
    'SABSBHBvc3RCCQoHcmVxdWVzdA==');

@$core.Deprecated('Use connectionReadyDescriptor instead')
const ConnectionReady$json = {
  '1': 'ConnectionReady',
};

/// Descriptor for `ConnectionReady`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionReadyDescriptor =
    $convert.base64Decode('Cg9Db25uZWN0aW9uUmVhZHk=');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'subscription_id', '3': 1, '4': 1, '5': 9, '10': 'subscriptionId'},
    {
      '1': 'connection_ready',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.social.example.eventbus.grpc.ConnectionReady',
      '9': 0,
      '10': 'connectionReady'
    },
    {
      '1': 'timeline',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.timeline.grpc.SubscribeTimelineResponse',
      '9': 0,
      '10': 'timeline'
    },
    {
      '1': 'post',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.social.example.features.posts.grpc.SubscribePostResponse',
      '9': 0,
      '10': 'post'
    },
  ],
  '8': [
    {'1': 'response'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBInCg9zdWJzY3JpcHRpb25faWQYASABKAlSDnN1YnNjcmlwdGlvbklkEloKEGNvbm'
    '5lY3Rpb25fcmVhZHkYAiABKAsyLS5zb2NpYWwuZXhhbXBsZS5ldmVudGJ1cy5ncnBjLkNvbm5l'
    'Y3Rpb25SZWFkeUgAUg9jb25uZWN0aW9uUmVhZHkSXgoIdGltZWxpbmUYAyABKAsyQC5zb2NpYW'
    'wuZXhhbXBsZS5mZWF0dXJlcy50aW1lbGluZS5ncnBjLlN1YnNjcmliZVRpbWVsaW5lUmVzcG9u'
    'c2VIAFIIdGltZWxpbmUSTwoEcG9zdBgEIAEoCzI5LnNvY2lhbC5leGFtcGxlLmZlYXR1cmVzLn'
    'Bvc3RzLmdycGMuU3Vic2NyaWJlUG9zdFJlc3BvbnNlSABSBHBvc3RCCgoIcmVzcG9uc2U=');

@$core.Deprecated('Use unsubscribeRequestDescriptor instead')
const UnsubscribeRequest$json = {
  '1': 'UnsubscribeRequest',
  '2': [
    {
      '1': 'context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.social.example.eventbus.grpc.ConnectionContext',
      '10': 'context'
    },
    {'1': 'subscription_id', '3': 2, '4': 1, '5': 9, '10': 'subscriptionId'},
  ],
};

/// Descriptor for `UnsubscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unsubscribeRequestDescriptor = $convert.base64Decode(
    'ChJVbnN1YnNjcmliZVJlcXVlc3QSSQoHY29udGV4dBgBIAEoCzIvLnNvY2lhbC5leGFtcGxlLm'
    'V2ZW50YnVzLmdycGMuQ29ubmVjdGlvbkNvbnRleHRSB2NvbnRleHQSJwoPc3Vic2NyaXB0aW9u'
    'X2lkGAIgASgJUg5zdWJzY3JpcHRpb25JZA==');
