import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/uuid.dart';

void main() {
  final shape = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('is a lower-case version 4 UUID', () {
    for (var i = 0; i < 200; i++) {
      expect(newUuid(), matches(shape));
    }
  });

  test('does not repeat', () {
    final ids = {for (var i = 0; i < 10000; i++) newUuid()};
    expect(ids, hasLength(10000));
  });

  test('recognises what it writes, and nothing else', () {
    expect(isUuid(newUuid()), isTrue);
    expect(isUuid('12'), isFalse);
    expect(isUuid('default'), isFalse);
  });
}
