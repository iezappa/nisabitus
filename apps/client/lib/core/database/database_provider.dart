import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The single database instance the whole app shares.
///
/// Overridden in tests with an in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
