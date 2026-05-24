import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';

final grpcCallOptionsProvider = Provider((_) => CallOptions());
