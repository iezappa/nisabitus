import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';
import 'package:nisabitus/features/update/domain/update_info.dart';

void main() {
  group('parseReleaseVersion', () {
    test('accepts a tag, a pubspec version and a plain version', () {
      expect(parseReleaseVersion('v1.2.3'), const AppVersion(1, 2, 3));
      expect(parseReleaseVersion('1.2.3+4'), const AppVersion(1, 2, 3));
      expect(parseReleaseVersion(' 1.2.3 '), const AppVersion(1, 2, 3));
    });

    test('refuses anything else', () {
      expect(parseReleaseVersion('latest'), isNull);
      expect(parseReleaseVersion('1.2'), isNull);
      expect(parseReleaseVersion(null), isNull);
    });

    test('orders numerically, major first', () {
      expect(
        parseReleaseVersion('1.10.0')! > parseReleaseVersion('1.9.9')!,
        isTrue,
      );
      expect(
        parseReleaseVersion('2.0.0')! > parseReleaseVersion('1.99.99')!,
        isTrue,
      );
      expect(parseReleaseVersion('v1.2.3'), parseReleaseVersion('1.2.3+9'));
    });
  });

  group('UpdateManifest.parse', () {
    test('reads the schema flag and the minimum supported version', () {
      final manifest = UpdateManifest.parse(
        '{"version":"1.4.0","schemaChange":true,"minSupportedVersion":"1.2.0"}',
      );
      expect(manifest.schemaChange, isTrue);
      expect(manifest.minSupportedVersion, const AppVersion(1, 2, 0));
    });

    test('falls back to no schema change for anything unreadable', () {
      expect(UpdateManifest.parse('nope').schemaChange, isFalse);
      expect(UpdateManifest.parse('{}').minSupportedVersion, isNull);
    });
  });

  test('an installed version below the minimum needs an intermediate step', () {
    final info = UpdateInfo(
      latest: const AppVersion(2, 0, 0),
      url: Uri.parse('https://example.org'),
      minSupportedVersion: const AppVersion(1, 5, 0),
    );
    expect(info.isUnsupportedFrom(const AppVersion(1, 4, 9)), isTrue);
    expect(info.isUnsupportedFrom(const AppVersion(1, 5, 0)), isFalse);
  });
}
