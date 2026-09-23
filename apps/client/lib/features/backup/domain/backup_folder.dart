/// A folder on the device that the app may keep writing to.
///
/// A port, like [BackupFiles], and for a sharper reason: what a folder is
/// differs by platform in a way the rest of the app should never see. On the
/// desktop it is a path. In a browser it is a handle the user granted, which
/// can be stored but whose permission may have to be asked for again, and
/// which some browsers do not offer at all.
abstract interface class BackupFolder {
  /// Whether this build can hold on to a folder between launches.
  ///
  /// False in a browser that has no File System Access API, where the only
  /// way out of the app is the save dialog and a dialog is not automatic.
  bool get isSupported;

  /// Asks the user to pick one. Returns what to call it on screen, or null
  /// if they backed out.
  Future<String?> choose();

  /// The folder picked before, if it is still there and still allowed.
  ///
  /// Returns null when nothing was ever picked. Throws
  /// [BackupFolderException] when one was picked and cannot be used now,
  /// because those are different answers: the first is a feature switched
  /// off, the second is a promise being broken.
  Future<String?> remembered();

  /// Writes a file into it, replacing one of the same name.
  Future<void> write(String fileName, String contents);

  /// Forgets the folder. The files already written stay where they are.
  Future<void> forget();
}
