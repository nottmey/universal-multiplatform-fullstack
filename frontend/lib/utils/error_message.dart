import 'package:client/api.dart' show ApiException;
import 'package:frontend/api/api_errors.dart';

String errorMessage(Object error) {
  return switch (error) {
    ApiErrorException(:final code, :final message) => '$code: $message',
    ApiException(:final code, :final message) => '$code: ${message ?? ''}',
    _ => error.toString(),
  };
}
