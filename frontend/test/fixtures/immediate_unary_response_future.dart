import 'package:async/async.dart';
import 'package:grpc/grpc.dart';

final class ImmediateUnaryResponseFuture<T> extends DelegatingFuture<T>
    implements ResponseFuture<T> {
  ImmediateUnaryResponseFuture(super.future);

  @override
  Future<Map<String, String>> get headers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<Map<String, String>> get trailers =>
      Future<Map<String, String>>.value(<String, String>{});

  @override
  Future<void> cancel() async {}
}
