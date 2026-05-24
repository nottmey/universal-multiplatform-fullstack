import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/grpc/grpc_connection_epoch_provider.dart';
import 'package:frontend/grpc/grpc_session_id_provider.dart';

final grpcConnectionContextProvider = Provider<ConnectionContext>((ref) {
  final sessionId = ref.watch(grpcSessionIdProvider);
  final epoch = ref.watch(grpcConnectionEpochProvider);
  return ConnectionContext(id: sessionId, epoch: Int64(epoch));
});
