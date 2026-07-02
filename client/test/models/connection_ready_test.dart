// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('ConnectionReady', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = ConnectionReady();
      final parsed = ConnectionReady.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(ConnectionReady.maybeFromJson(null), isNull);
    });
  });
}
