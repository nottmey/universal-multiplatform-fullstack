import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' show ClientException;

const Duration _grpcConnectionAttemptTimeout = Duration(seconds: 5);

/// Per-RPC attempt timeout for subscribe, unsubscribe, and similar unary calls.
final grpcConnectionAttemptTimeoutProvider = Provider<Duration>(
  (ref) => _grpcConnectionAttemptTimeout,
);

/// How long to wait for `connection_ready` on the EventBus stream before retrying.
final eventBusHandshakeTimeoutProvider = Provider<Duration>(
  (ref) => _grpcConnectionAttemptTimeout,
);

const int boundedRetryCount = 5;

const Duration _retryInitialDelay = Duration(milliseconds: 500);
const Duration _retryMaxDelay = Duration(seconds: 16);
const double _retryJitterFraction = 0.2;

bool isOfflineFailure(Object e) {
  return switch (e) {
    TimeoutException() ||
    SocketException() ||
    IOException() ||
    ClientException() => true,
    GrpcError(:final code) =>
      code == StatusCode.unavailable || code == StatusCode.deadlineExceeded,
    _ => false,
  };
}

Duration unboundedRetryDelay(int retryCount) {
  final cappedExponent = retryCount < 5 ? retryCount : 5;
  final baseMilliseconds =
      _retryInitialDelay.inMilliseconds * (1 << cappedExponent);
  final cappedMilliseconds = baseMilliseconds > _retryMaxDelay.inMilliseconds
      ? _retryMaxDelay.inMilliseconds
      : baseMilliseconds;
  final jitterSpread = cappedMilliseconds * _retryJitterFraction;
  final jitter = (Random().nextDouble() * 2 - 1) * jitterSpread;
  final milliseconds = (cappedMilliseconds + jitter).round();
  return Duration(milliseconds: milliseconds < 0 ? 0 : milliseconds);
}

Duration? boundedRetryDelay(int retryCount) {
  if (retryCount < 0 || retryCount >= boundedRetryCount) {
    return null;
  }
  return unboundedRetryDelay(retryCount);
}

Duration? offlineUnboundedRetryDelay(int count, Object e) {
  return isOfflineFailure(e) ? unboundedRetryDelay(count) : null;
}

/// Stops [offlineBoundedRetryLoop] when [shouldContinue] is false (e.g. provider disposed).
final class RetryLoopAborted implements Exception {
  const RetryLoopAborted();
}

Future<T> offlineBoundedRetryLoop<T>({
  required bool Function() shouldContinue,
  required Future<T> Function() operation,
}) async {
  var retryCount = 0;
  var succeeded = false;
  late T result;
  while (shouldContinue() && !succeeded) {
    try {
      result = await operation();
      succeeded = true;
    } catch (e) {
      if (!isOfflineFailure(e)) {
        rethrow;
      }
      if (!shouldContinue()) {
        break;
      }
      final delay = boundedRetryDelay(retryCount);
      if (delay == null) {
        rethrow;
      }
      await Future<void>.delayed(delay);
      retryCount++;
    }
  }
  if (succeeded) {
    return result;
  }
  throw const RetryLoopAborted();
}
