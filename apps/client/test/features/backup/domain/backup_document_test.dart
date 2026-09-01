import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/backup/domain/backup_document.dart';

void main() {
  final exportedAt = DateTime(2026, 3, 11, 21, 30);

  BackupDocument document({
    Map<String, List<Map<String, dynamic>>>? tables,
    int schemaVersion = 4,
  }) => BackupDocument(
    schemaVersion: schemaVersion,
    exportedAt: exportedAt,
    tables:
        tables ??
        {
          'habits': [
            {'id': 1, 'name': 'Meditar'},
          ],
          'sleep_logs': const [],
        },
  );

  /// A document as it arrives from a file: already decoded JSON.
  Map<String, dynamic> raw({
    Object? format = BackupDocument.currentFormat,
    Object? schemaVersion = 4,
    Object? tables,
  }) => {
    'app': BackupDocument.appId,
    'format': format,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.millisecondsSinceEpoch,
    'tables':
        tables ??
        {
          'habits': [
            {'id': 1, 'name': 'Meditar'},
          ],
        },
  };

  group('encoding', () {
    test('stamps the format and the schema it was taken from', () {
      final decoded = jsonDecode(document().encode()) as Map<String, dynamic>;

      expect(decoded['app'], BackupDocument.appId);
      expect(decoded['app'], 'nisabitus');
      expect(decoded['format'], BackupDocument.currentFormat);
      expect(decoded['schemaVersion'], 4);
    });

    test('round-trips through its own parser', () {
      final restored = BackupDocument.parse(
        document().encode(),
        supportedSchemaVersion: 4,
      );

      expect(restored.schemaVersion, 4);
      expect(restored.exportedAt, exportedAt);
      expect(restored.tables['habits'], hasLength(1));
      expect(restored.tables['habits']!.single['name'], 'Meditar');
    });

    test('keeps a table that holds nothing', () {
      // An empty table is not the same as a missing one: it says the export
      // looked and found nothing, so the restore should empty it too.
      final restored = BackupDocument.parse(
        document().encode(),
        supportedSchemaVersion: 4,
      );

      expect(restored.tables.containsKey('sleep_logs'), isTrue);
      expect(restored.tables['sleep_logs'], isEmpty);
    });

    test('counts the rows it carries', () {
      expect(document().rowCount, 1);
      expect(
        document(tables: {'habits': const [], 'streaks': const []}).rowCount,
        0,
      );
    });
  });

  group('parsing', () {
    test('accepts a well formed document', () {
      final parsed = BackupDocument.parse(
        jsonEncode(raw()),
        supportedSchemaVersion: 4,
      );

      expect(parsed.tables['habits']!.single['id'], 1);
    });

    test('refuses text that is not JSON at all', () {
      expect(
        () => BackupDocument.parse('not a backup', supportedSchemaVersion: 4),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses JSON that is not an object', () {
      expect(
        () => BackupDocument.parse('[1, 2, 3]', supportedSchemaVersion: 4),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('reads a file stamped with the name the app used to carry', () {
      final legacy = raw()..['app'] = BackupDocument.legacyAppId;

      final restored = BackupDocument.parse(
        jsonEncode(legacy),
        supportedSchemaVersion: 4,
      );

      expect(restored.schemaVersion, 4);
      expect(restored.tables['habits'], hasLength(1));
    });

    test('refuses a file from another app', () {
      final foreign = raw()..['app'] = 'something-else';

      expect(
        () => BackupDocument.parse(
          jsonEncode(foreign),
          supportedSchemaVersion: 4,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a format it does not know', () {
      expect(
        () => BackupDocument.parse(
          jsonEncode(raw(format: BackupDocument.currentFormat + 1)),
          supportedSchemaVersion: 4,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a backup from a newer schema', () {
      // Restoring it would drop whatever the newer version added, which is
      // data loss dressed up as a restore.
      expect(
        () => BackupDocument.parse(
          jsonEncode(raw(schemaVersion: 5)),
          supportedSchemaVersion: 4,
        ),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            BackupProblem.newerVersion,
          ),
        ),
      );
    });

    test('accepts a backup from an older schema', () {
      // Columns added since are absent from the rows; they come back on
      // their defaults, which is what the migration would have done.
      final parsed = BackupDocument.parse(
        jsonEncode(raw(schemaVersion: 2)),
        supportedSchemaVersion: 4,
      );

      expect(parsed.schemaVersion, 2);
    });

    test('refuses a document with no tables at all', () {
      final headerOnly = raw()..remove('tables');

      expect(
        () => BackupDocument.parse(
          jsonEncode(headerOnly),
          supportedSchemaVersion: 4,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a table that is not a list of rows', () {
      expect(
        () => BackupDocument.parse(
          jsonEncode(raw(tables: {'habits': 'nope'})),
          supportedSchemaVersion: 4,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a row that is not an object', () {
      expect(
        () => BackupDocument.parse(
          jsonEncode(
            raw(
              tables: {
                'habits': [1, 2],
              },
            ),
          ),
          supportedSchemaVersion: 4,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a document with no export date', () {
      final undated = raw()..remove('exportedAt');

      expect(
        () => BackupDocument.parse(
          jsonEncode(undated),
          supportedSchemaVersion: 4,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
