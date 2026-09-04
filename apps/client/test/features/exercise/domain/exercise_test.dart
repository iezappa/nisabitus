import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/exercise/domain/exercise.dart';

void main() {
  group('Exercise', () {
    test('rejects a blank name', () {
      expect(() => Exercise(id: 1, name: '   '), throwsArgumentError);
    });

    test('trims the name it is given', () {
      expect(Exercise(id: 1, name: '  Sentadilla  ').name, 'Sentadilla');
    });
  });
}
