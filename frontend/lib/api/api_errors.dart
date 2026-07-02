import 'package:client/api.dart' show ApiError;
import 'package:flutter/foundation.dart';

/// A structured error the server reported, either as a non-2xx `ApiError`
/// body or as an EventBus `error` envelope.
@immutable
final class ApiErrorException implements Exception {
  const ApiErrorException({required this.code, required this.message});

  ApiErrorException.fromApiError(ApiError error)
    : this(code: error.code, message: error.message);

  final String code;
  final String message;

  @override
  String toString() => 'ApiErrorException($code): $message';
}

/// The EventBus socket ended before or without completing the
/// connectionReady handshake; treated as an offline failure.
@immutable
final class EventBusUnavailableException implements Exception {
  const EventBusUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'EventBusUnavailableException: $message';
}
