// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('PostSubscriptionRequest', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = PostSubscriptionRequest(postId: 'example');
      final parsed = PostSubscriptionRequest.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(PostSubscriptionRequest.maybeFromJson(null), isNull);
    });

    test('maybeFromJson throws FormatException on invalid input', () {
      expect(
        () => PostSubscriptionRequest.maybeFromJson(<String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
