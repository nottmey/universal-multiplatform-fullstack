import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/utils/localhost.dart';
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
    host: _grpcHost.isNotEmpty ? _grpcHost : localhost,
    port: int.parse(_grpcPort),
    transportSecure: _grpcTls == 'true',
  ),
);
