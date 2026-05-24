import 'package:grpc/grpc_or_grpcweb.dart';

String grpcUserFacingMessage(Object error) {
  if (error is GrpcError) {
    return '${error.codeName} (${error.code}): ${error.message}';
  }
  return error.toString();
}
