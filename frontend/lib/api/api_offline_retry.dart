import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:client/api.dart' show ApiException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/api_errors.dart';
import 'package:http/http.dart' show ClientException;
import 'package:web_socket_channel/web_socket_channel.dart';

const Duration _apiRequestTimeout = Duration(seconds: 5);

/// Per-request attempt timeout for REST calls and WebSocket subscribe frames.
final apiRequestTimeoutProvider = Provider<Duration>(
  (ref) => _apiRequestTimeout,
);

/// How long to wait for the connectionReady handshake on the EventBus socket
/// before retrying.
final eventBusHandshakeTimeoutProvider = Provider<Duration>(
  (ref) => _apiRequestTimeout,
);

const int boundedRetryCount = 5;

const Duration _retryInitialDelay = Duration(milliseconds: 500);
const Duration _retryMaxDelay = Duration(seconds: 16);
const double _retryJitterFraction = 0.2;

/// HTTP statuses that signal a transient/offline server condition and are
/// safe to retry (bad gateway, service unavailable, gateway timeout).
const Set<int> _offlineHttpStatuses = {502, 503, 504};

bool isOfflineFailure(Object e) {
  return switch (e) {
    TimeoutException() ||
    SocketException() ||
    IOException() ||
    ClientException() ||
    WebSocketChannelException() ||
    EventBusUnavailableException() => true,
    ApiException(:final code) => _offlineHttpStatuses.contains(code),
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
