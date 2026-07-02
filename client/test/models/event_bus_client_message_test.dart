// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('EventBusClientMessage', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = EventBusClientMessage();
      final parsed = EventBusClientMessage.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(EventBusClientMessage.maybeFromJson(null), isNull);
    });
  });
}
