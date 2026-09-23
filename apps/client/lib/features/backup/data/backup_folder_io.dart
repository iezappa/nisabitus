import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auto_backup.dart';
import '../domain/backup_folder.dart';

/// A real folder on a real filesystem, for the desktop and mobile builds.
///
/// The path is all that is kept, because a path is all the platform gives:
/// the folder may be renamed, unplugged or deleted between launches, and the
/// only way to find out is to try.
class IoBackupFolder implements BackupFolder {
  IoBackupFolder(this._prefs);

  final SharedPreferences _prefs;

  static const pathKey = 'backup.autoFolder';

  @override
  bool get isSupported => true;

  @override
  Future<String?> choose() async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return null;

    await _prefs.setString(pathKey, path);
    return path;
  }

  @override
  Future<String?> remembered() async {
    final path = _prefs.getString(pathKey);
    if (path == null) return null;

    if (!Directory(path).existsSync()) {
      throw const BackupFolderException(AutoBackupProblem.folderGone);
    }
    return path;
  }

  @override
  Future<void> write(String fileName, String contents) async {
    final path = _prefs.getString(pathKey);
    if (path == null) {
      throw const BackupFolderException(AutoBackupProblem.folderGone);
    }

    final folder = Directory(path);
    if (!folder.existsSync()) {
      throw const BackupFolderException(AutoBackupProblem.folderGone);
    }

    try {
      // Written beside its final name and moved into place, so a copy
      // interrupted halfway — a full disk, a laptop lid — cannot leave a
      // truncated file wearing the name of a good one.
      final scratch = File('${folder.path}${Platform.pathSeparator}.$fileName');
      await scratch.writeAsString(contents, flush: true);
      await scratch.rename('${folder.path}${Platform.pathSeparator}$fileName');
    } on FileSystemException {
      throw const BackupFolderException(AutoBackupProblem.failed);
    }
  }

  @override
  Future<void> forget() => _prefs.remove(pathKey).then((_) {});
}

/// The folder for this build. See `backup_folder_platform.dart`.
BackupFolder backupFolderFor(SharedPreferences prefs) => IoBackupFolder(prefs);
