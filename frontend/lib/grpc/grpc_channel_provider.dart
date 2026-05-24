import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_or_grpcweb.dart';
// ignore: implementation_imports — grpc.dart exposes the HTTP/2 ClientChannel class only; the shared API uses this abstract type for grpc-web.
import 'package:grpc/src/client/channel.dart' show ClientChannel;

const String _grpcHost = String.fromEnvironment('GRPC_HOST', defaultValue: '');
const String _grpcPort = String.fromEnvironment(
  'GRPC_PORT',
  defaultValue: '8080',
);
const String _grpcTls = String.fromEnvironment(
  'GRPC_TLS',
  defaultValue: 'false',
);

final grpcChannelProvider = Provider<ClientChannel>(
  (_) => GrpcOrGrpcWebClientChannel.toSingleEndpoint(
    host: _grpcHost.isNotEmpty
        ? _grpcHost
        : (kIsWeb
              ? '127.0.0.1'
              : (defaultTargetPlatform == TargetPlatform.android
                    ? '10.0.2.2'
                    : '127.0.0.1')),
    port: int.parse(_grpcPort),
    transportSecure: _grpcTls == 'true',
  ),
);
