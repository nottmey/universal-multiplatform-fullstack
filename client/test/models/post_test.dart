// GENERATED — do not hand-edit.
import 'package:client/api.dart';
import 'package:test/test.dart';

void main() {
  group('Post', () {
    test('round-trips via maybeFromJson/toJson', () {
      const instance = Post(
        postId: 'example',
        body: 'example',
        postedAtMillis: 0,
      );
      final parsed = Post.maybeFromJson(instance.toJson())!;
      expect(parsed, equals(instance));
      expect(parsed.hashCode, equals(instance.hashCode));
    });

    test('maybeFromJson returns null on null input', () {
      expect(Post.maybeFromJson(null), isNull);
    });

    test('maybeFromJson throws FormatException on invalid input', () {
      expect(
        () => Post.maybeFromJson(<String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
