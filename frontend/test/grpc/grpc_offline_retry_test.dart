import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/grpc/grpc_offline_retry.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' show ClientException;

void main() {
  group('isOfflineFailure', () {
    test('returns true for unavailable GrpcError', () {
      expect(isOfflineFailure(GrpcError.unavailable('offline')), isTrue);
    });

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

    test('returns false for failedPrecondition GrpcError', () {
      expect(
        isOfflineFailure(
          GrpcError.failedPrecondition('no active EventBus stream'),
        ),
        isFalse,
      );
    });

    test('returns false for unknown GrpcError', () {
      expect(isOfflineFailure(GrpcError.unknown('bug')), isFalse);
    });

    test('returns true for deadlineExceeded GrpcError', () {
      expect(isOfflineFailure(GrpcError.deadlineExceeded('slow')), isTrue);
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
            throw GrpcError.unavailable('offline');
          }
          return 'ok';
        },
      );
      expect(result, 'ok');
      expect(attempts, 3);
    });

    test('rethrows after exhausting bounded delays', () async {
      var attempts = 0;
      await expectLater(
        offlineBoundedRetryLoop(
          shouldContinue: () => true,
          operation: () async {
            attempts++;
            throw GrpcError.unavailable('offline');
          },
        ),
        throwsA(isA<GrpcError>()),
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
            throw GrpcError.unavailable('offline');
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
        offlineUnboundedRetryDelay(
          0,
          GrpcError.failedPrecondition('logic error'),
        ),
        isNull,
      );
    });

    test('returns delay for offline errors', () {
      expect(
        offlineUnboundedRetryDelay(0, GrpcError.unavailable('offline')),
        isNotNull,
      );
    });
  });
}
