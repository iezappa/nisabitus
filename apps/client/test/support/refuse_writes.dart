import 'package:nisabitus/core/database/app_database.dart';

/// Makes every [operation] on [table] throw, the way a full or locked store
/// would, so a test can watch what the user is told when a write fails.
Future<void> refuseWrites(
  AppDatabase db,
  String table, {
  String operation = 'INSERT',
}) => db.customStatement(
  'CREATE TRIGGER refuse_${operation.toLowerCase()}_$table '
  'BEFORE $operation ON $table '
  "BEGIN SELECT RAISE(ABORT, 'refused'); END",
);
