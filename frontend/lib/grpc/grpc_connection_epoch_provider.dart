import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GrpcConnectionEpochNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @visibleForTesting
  void bumpEpoch() => state++;
}

final grpcConnectionEpochProvider = NotifierProvider(
  GrpcConnectionEpochNotifier.new,
);

extension GrpcConnectionEpochWidgetRefExtension on WidgetRef {
  Future<void> Function() get onForceRefresh => () {
    read(grpcConnectionEpochProvider.notifier).bumpEpoch();
    return Future<void>.delayed(const Duration(milliseconds: 500));
  };
}
