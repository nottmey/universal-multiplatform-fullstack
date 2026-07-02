// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('UnsubscribeCommand', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = UnsubscribeCommand(subscriptionId: 'example');
      final parsed = UnsubscribeCommand.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(UnsubscribeCommand.maybeFromJson(null), isNull);
    });

    test('maybeFromJson throws FormatException on invalid input', () {
      expect(
        () => UnsubscribeCommand.maybeFromJson(<String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
