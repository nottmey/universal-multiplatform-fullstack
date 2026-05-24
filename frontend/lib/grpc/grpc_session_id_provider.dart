import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final grpcSessionIdProvider = Provider((_) => const Uuid().v4());
