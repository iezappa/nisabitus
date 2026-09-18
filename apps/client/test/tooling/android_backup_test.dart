import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android's automatic backup would copy the Drift database — journal,
/// sleep, food, medication and the rest — into the user's Google account. PRIVACY.md promises
/// the data never leaves the device, so the app opts out, and this test keeps
/// the opt-out from being dropped by a Flutter template update.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  test('the app opts out of Android backup', () {
    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('the app opts out of cloud backup and device transfer on API 31+', () {
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );

    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
    expect(
      RegExp(r'<exclude\s+domain="[^"]+"').allMatches(rules).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('older API levels have nothing to back up either', () {
    expect(
      manifest,
      contains('android:fullBackupContent="@xml/full_backup_content"'),
    );
    final content = File('android/app/src/main/res/xml/full_backup_content.xml')
        .readAsStringSync();
    expect(content, contains('<exclude'));
  });
}
