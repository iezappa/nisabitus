import 'dart:convert';

/// Why a file could not be read as a backup.
///
/// Separated from the message so the UI can say something a person
/// understands instead of showing a parser's complaint.
enum BackupProblem {
  /// Not JSON, not an object, or not this app's file.
  notABackup,

  /// Written by a newer version of Nísabit than the one reading it.
  newerVersion,

  /// This app's file, this app's version, but the contents do not hold up.
  corrupt,
}

/// Thrown when a file cannot be trusted as a backup.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason, [this.detail]);

  final BackupProblem reason;

  /// For the log, not for the user.
  final String? detail;

  @override
  String toString() =>
      'BackupFormatException(${reason.name}${detail == null ? '' : ': $detail'})';
}

/// Everything the app holds, as one portable document.
///
/// Rows are carried verbatim, ids included, so a restore puts the store back
/// exactly as it was rather than rebuilding it and hoping the references
/// still line up.
class BackupDocument {
  const BackupDocument({
    required this.schemaVersion,
    required this.exportedAt,
    required this.tables,
  });

  /// Reads a file's text, refusing anything it cannot vouch for.
  ///
  /// [supportedSchemaVersion] is the schema of the database doing the
  /// reading. A backup from an older schema is fine — columns added since
  /// come back on their defaults, which is what a migration would have done.
  /// A newer one is not: restoring it would silently drop whatever that
  /// version added, which is data loss dressed up as a restore.
  factory BackupDocument.parse(
    String source, {
    required int supportedSchemaVersion,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw BackupFormatException(BackupProblem.notABackup, '$error');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException(
        BackupProblem.notABackup,
        'The document is not a JSON object',
      );
    }

    if (decoded['app'] != appId) {
      throw const BackupFormatException(
        BackupProblem.notABackup,
        'The document does not belong to this app',
      );
    }

    final format = decoded['format'];
    if (format is! int || format > currentFormat) {
      throw BackupFormatException(
        format is int ? BackupProblem.newerVersion : BackupProblem.notABackup,
        'Unsupported format: $format',
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      throw const BackupFormatException(
        BackupProblem.corrupt,
        'The schema version is missing',
      );
    }
    if (schemaVersion > supportedSchemaVersion) {
      throw BackupFormatException(
        BackupProblem.newerVersion,
        'Backup schema $schemaVersion is newer than $supportedSchemaVersion',
      );
    }

    final exportedAt = decoded['exportedAt'];
    if (exportedAt is! int) {
      throw const BackupFormatException(
        BackupProblem.corrupt,
        'The export date is missing',
      );
    }

    final tables = decoded['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const BackupFormatException(
        BackupProblem.corrupt,
        'The document carries no tables',
      );
    }

    return BackupDocument(
      schemaVersion: schemaVersion,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(exportedAt),
      tables: {
        for (final entry in tables.entries)
          entry.key: _readRows(entry.key, entry.value),
      },
    );
  }

  /// Stamped on every file so another app's JSON cannot be mistaken for one.
  static const appId = 'nisabit';

  /// The document's own layout, which moves independently of the database
  /// schema: a rearranged file is not a migrated store.
  static const currentFormat = 1;

  /// The database schema the rows were taken from.
  final int schemaVersion;

  final DateTime exportedAt;

  /// Table name to its rows, each row a column-to-value map.
  final Map<String, List<Map<String, dynamic>>> tables;

  /// How many rows the document carries, across every table.
  int get rowCount => tables.values.fold(0, (sum, rows) => sum + rows.length);

  String encode() => jsonEncode({
    'app': appId,
    'format': currentFormat,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.millisecondsSinceEpoch,
    'tables': tables,
  });

  static List<Map<String, dynamic>> _readRows(String table, Object? value) {
    if (value is! List) {
      throw BackupFormatException(
        BackupProblem.corrupt,
        'Table $table is not a list of rows',
      );
    }

    return [
      for (final row in value)
        if (row is Map<String, dynamic>)
          row
        else
          throw BackupFormatException(
            BackupProblem.corrupt,
            'Table $table holds a row that is not an object',
          ),
    ];
  }
}
