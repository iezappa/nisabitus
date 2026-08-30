/// Where a backup file comes from and where it goes.
///
/// A port rather than a direct call to the picker, so the export and import
/// flows can be driven in a test without a native dialog on screen.
abstract interface class BackupFiles {
  /// Asks the user where to put [contents].
  ///
  /// Returns false if they backed out, which is not a failure.
  Future<bool> save(String fileName, String contents);

  /// Asks the user for a file and reads it.
  ///
  /// Returns null if they backed out.
  Future<String?> open();
}
