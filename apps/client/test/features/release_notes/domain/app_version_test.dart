import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';

void main() {
  group('AppVersion.parse', () {
    test('reads the three numbers', () {
      final version = AppVersion.parse('1.2.3');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
    });

    test('tolerates the surrounding whitespace of a hand-written file', () {
      expect(AppVersion.parse(' 1.2.3 '), AppVersion.parse('1.2.3'));
    });

    test('rejects anything that is not three numbers', () {
      expect(() => AppVersion.parse('1.2'), throwsFormatException);
      expect(() => AppVersion.parse('1.2.3.4'), throwsFormatException);
      expect(() => AppVersion.parse('1.2.x'), throwsFormatException);
      expect(() => AppVersion.parse(''), throwsFormatException);
    });

    test('rejects a negative number', () {
      expect(() => AppVersion.parse('1.-2.3'), throwsFormatException);
    });

    test('rejects a build suffix, which this app does not order by', () {
      expect(() => AppVersion.parse('1.2.3+4'), throwsFormatException);
    });
  });

  group('AppVersion ordering', () {
    test('compares each number, not the text', () {
      // The bug this guards: '1.10.0' sorts before '1.9.0' as a string.
      expect(
        AppVersion.parse('1.10.0').compareTo(AppVersion.parse('1.9.0')),
        greaterThan(0),
      );
    });

    test('weighs major over minor over patch', () {
      expect(AppVersion.parse('2.0.0') > AppVersion.parse('1.99.99'), isTrue);
      expect(AppVersion.parse('1.2.0') > AppVersion.parse('1.1.99'), isTrue);
      expect(AppVersion.parse('1.1.2') > AppVersion.parse('1.1.1'), isTrue);
    });

    test('treats the same numbers as the same version', () {
      expect(AppVersion.parse('1.2.3'), AppVersion.parse('1.2.3'));
      expect(
        AppVersion.parse('1.2.3').hashCode,
        AppVersion.parse('1.2.3').hashCode,
      );
      expect(AppVersion.parse('1.2.3') > AppVersion.parse('1.2.3'), isFalse);
    });
  });

  test('reads back as it was written', () {
    expect(AppVersion.parse('1.2.3').toString(), '1.2.3');
  });
}
