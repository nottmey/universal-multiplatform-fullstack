// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('ApiError', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = ApiError(code: 'example', message: 'example');
      final parsed = ApiError.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(ApiError.maybeFromJson(null), isNull);
    });

    test('maybeFromJson throws FormatException on invalid input', () {
      expect(
        () => ApiError.maybeFromJson(<String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
