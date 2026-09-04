/// What a restore actually put back.
///
/// The document is what the file claimed; this is what the store took. They
/// differ whenever the file was written by a version that had tables this
/// one no longer has, and the user is told the smaller, true number rather
/// than the flattering one.
class RestoreReport {
  const RestoreReport({required this.rows, required this.ignoredTables});

  /// Rows written, counted as they were written.
  final int rows;

  /// Tables the file carried rows for that this version has no home for.
  ///
  /// Empty tables are not listed: nothing was lost by skipping them.
  final Set<String> ignoredTables;
}
