import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Upper bound of [unboundedRetryDelay] without jitter (matches production caps).
Duration maxOfflineRetryDelayWithoutJitter(int retryCount) {
  const initialDelayMilliseconds = 500;
  const maxDelayMilliseconds = 16000;
  final cappedExponent = retryCount < 5 ? retryCount : 5;
  final baseMilliseconds = initialDelayMilliseconds * (1 << cappedExponent);
  final cappedMilliseconds = baseMilliseconds > maxDelayMilliseconds
      ? maxDelayMilliseconds
      : baseMilliseconds;
  return Duration(milliseconds: cappedMilliseconds);
}

/// Test handshake timeout from [createEventBusProviderContainer].
const Duration eventBusTestHandshakeTimeout = Duration(milliseconds: 20);

extension EventBusFakeAsync on FakeAsync {
  void flush() {
    elapse(Duration.zero);
    flushMicrotasks();
  }

  /// Drains short async work such as [StreamSubscription.cancel] in provider catch paths.
  void drainPendingAsyncWork() {
    for (var step = 0; step < 20; step++) {
      elapse(const Duration(milliseconds: 1));
      flushMicrotasks();
    }
  }

  /// Elapses fake time for one offline retry backoff at [failureIndex].
  void elapseOfflineRetryBackoff({required int failureIndex}) {
    elapse(eventBusTestHandshakeTimeout);
    flushMicrotasks();
    elapse(
      maxOfflineRetryDelayWithoutJitter(failureIndex) +
          const Duration(milliseconds: 50),
    );
    flushMicrotasks();
  }

  /// Elapses fake time for [failureCount] offline failures (Riverpod or bounded RPC loop).
  void elapseOfflineRetryDelays({required int failureCount}) {
    for (var failureIndex = 0; failureIndex < failureCount; failureIndex++) {
      elapseOfflineRetryBackoff(failureIndex: failureIndex);
    }
  }

  void pumpUntil(bool Function() condition) {
    var steps = 0;
    while (!condition() && steps < 200) {
      elapse(const Duration(milliseconds: 50));
      flushMicrotasks();
      steps++;
    }
    expect(
      condition(),
      isTrue,
      reason: 'condition not met before fake-async budget',
    );
  }

  /// Waits for [eventBusProvider] to succeed after [failuresBeforeSuccess] offline failures.
  void waitForEventBusAfterOfflineFailures({
    required Future<void> Function() connect,
    required int failuresBeforeSuccess,
    required int Function() readAttempts,
  }) {
    var connected = false;
    unawaited(connect().then((_) => connected = true));
    flush();
    drainPendingAsyncWork();

    for (
      var failureIndex = 0;
      failureIndex < failuresBeforeSuccess;
      failureIndex++
    ) {
      pumpUntil(() => readAttempts() > failureIndex);
      drainPendingAsyncWork();
      elapseOfflineRetryBackoff(failureIndex: failureIndex);
      drainPendingAsyncWork();
    }

    pumpUntil(() => readAttempts() == failuresBeforeSuccess + 1);
    drainPendingAsyncWork();
    pumpUntil(() => connected);
  }

  void expectStableEventBusAttempts({
    required int expectedAttempts,
    required int Function() readAttempts,
  }) {
    flush();
    expect(readAttempts(), expectedAttempts);
    elapse(const Duration(seconds: 2));
    flushMicrotasks();
    expect(readAttempts(), expectedAttempts);
  }
}
