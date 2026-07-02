// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('PostEvent', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = PostEvent();
      final parsed = PostEvent.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(PostEvent.maybeFromJson(null), isNull);
    });
  });
}
