import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Removes the SQLite file and whatever journal sits next to it.
///
/// The location is the one `drift_flutter` opens by default: the application
/// documents directory, `<name>.sqlite`. Changing where the database is
/// opened means changing this too.
Future<void> eraseLocalStore() async {
  final directory = await getApplicationDocumentsDirectory();
  final base =
      '${directory.path}${Platform.pathSeparator}${AppDatabase.storeName}.sqlite';

  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final file = File('$base$suffix');
    if (file.existsSync()) await file.delete();
  }
}
