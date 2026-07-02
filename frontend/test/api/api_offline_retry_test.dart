import 'dart:async';
import 'dart:io';

import 'package:client/api.dart' show ApiException;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api_errors.dart';
import 'package:frontend/api/api_offline_retry.dart';
import 'package:http/http.dart' show ClientException;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('isOfflineFailure', () {
    test('returns true for TimeoutException', () {
      expect(isOfflineFailure(TimeoutException('timed out')), isTrue);
    });

    test('returns true for SocketException', () {
      expect(
        isOfflineFailure(const SocketException('connection refused')),
        isTrue,
      );
    });

    test('returns true for ClientException', () {
      expect(isOfflineFailure(ClientException('transport failed')), isTrue);
    });

    test('returns true for WebSocketChannelException', () {
      expect(
        isOfflineFailure(WebSocketChannelException('socket down')),
        isTrue,
      );
    });

    test('returns true for EventBusUnavailableException', () {
      expect(
        isOfflineFailure(
          const EventBusUnavailableException('closed before ready'),
        ),
        isTrue,
      );
    });

    test('returns true for 503/502/504 ApiException', () {
      expect(isOfflineFailure(const ApiException(503, 'unavailable')), isTrue);
      expect(isOfflineFailure(const ApiException(502, 'bad gateway')), isTrue);
      expect(isOfflineFailure(const ApiException(504, 'timeout')), isTrue);
    });

    test('returns false for 4xx ApiException', () {
      expect(isOfflineFailure(const ApiException(400, 'bad request')), isFalse);
      expect(
        isOfflineFailure(const ApiException(401, 'unauthenticated')),
        isFalse,
      );
    });

    test('returns false for structured ApiErrorException', () {
      expect(
        isOfflineFailure(
          const ApiErrorException(code: 'INVALID_ARGUMENT', message: 'nope'),
        ),
        isFalse,
      );
    });
  });

  group('boundedRetryDelay', () {
    test(
      'reuses exponential jittered backoff until attempt budget is exhausted',
      () {
        expect(
          boundedRetryDelay(0)!.inMilliseconds,
          inInclusiveRange(400, 600),
        );
        expect(
          boundedRetryDelay(4)!.inMilliseconds,
          inInclusiveRange(6400, 9600),
        );
        expect(boundedRetryDelay(5), isNull);
      },
    );
  });

  group('offlineBoundedRetryLoop', () {
    test('retries until operation succeeds within attempt budget', () async {
      var attempts = 0;
      final result = await offlineBoundedRetryLoop(
        shouldContinue: () => true,
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw const SocketException('offline');
          }
          return 'ok';
        },
      );
      expect(result, 'ok');
      expect(attempts, 3);
    });

    test('rethrows non-offline errors immediately', () async {
      var attempts = 0;
      await expectLater(
        offlineBoundedRetryLoop(
          shouldContinue: () => true,
          operation: () async {
            attempts++;
            throw const ApiException(400, 'bad request');
          },
        ),
        throwsA(isA<ApiException>()),
      );
      expect(attempts, 1);
    });

    test('rethrows after exhausting bounded delays', () async {
      var attempts = 0;
      await expectLater(
        offlineBoundedRetryLoop(
          shouldContinue: () => true,
          operation: () async {
            attempts++;
            throw const SocketException('offline');
          },
        ),
        throwsA(isA<SocketException>()),
      );
      expect(attempts, boundedRetryCount + 1);
    });

    test('aborts with RetryLoopAborted when shouldContinue is false', () async {
      var attempts = 0;
      var mayContinue = true;

      await expectLater(
        offlineBoundedRetryLoop(
          shouldContinue: () => mayContinue,
          operation: () async {
            attempts++;
            mayContinue = false;
            throw const SocketException('offline');
          },
        ),
        throwsA(isA<RetryLoopAborted>()),
      );
      expect(attempts, 1);
    });
  });

  group('unboundedRetryDelay', () {
    test('caps base delay at 16 seconds', () {
      expect(unboundedRetryDelay(0).inMilliseconds, inInclusiveRange(400, 600));
      expect(
        unboundedRetryDelay(4).inMilliseconds,
        inInclusiveRange(6400, 9600),
      );
      expect(
        unboundedRetryDelay(10).inMilliseconds,
        inInclusiveRange(12800, 19200),
      );
    });
  });

  group('offlineUnboundedRetryDelay', () {
    test('returns null for non-offline errors', () {
      expect(
        offlineUnboundedRetryDelay(0, const ApiException(400, 'logic error')),
        isNull,
      );
    });

    test('returns delay for offline errors', () {
      expect(
        offlineUnboundedRetryDelay(0, const SocketException('offline')),
        isNotNull,
      );
    });
  });
}
