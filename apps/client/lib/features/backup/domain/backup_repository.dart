import 'backup_document.dart';

/// The port the backup module talks to.
abstract interface class BackupRepository {
  /// Everything currently stored, as one document.
  Future<BackupDocument> export();

  /// Replaces the whole store with what [document] holds.
  ///
  /// Replace, not merge. Merging twenty-two tables that reference each other by
  /// id would mean renumbering half of them and hoping every reference was
  /// found — a lot of surface for silent corruption. Replacing is something
  /// the user can reason about, and the UI says so before it runs.
  ///
  /// All or nothing: it either finishes or leaves the store as it was.
  Future<void> restore(BackupDocument document);
}
