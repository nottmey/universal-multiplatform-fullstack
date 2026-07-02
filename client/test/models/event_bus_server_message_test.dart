// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('EventBusServerMessage', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = EventBusServerMessage();
      final parsed = EventBusServerMessage.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(EventBusServerMessage.maybeFromJson(null), isNull);
    });
  });
}
