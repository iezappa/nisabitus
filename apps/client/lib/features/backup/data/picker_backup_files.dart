import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/backup_files.dart';

/// The native save and open dialogs, behind [BackupFiles].
///
/// The picker writes the file itself, so nothing here touches dart:io and
/// the web build works on the same code as the desktop one.
class PickerBackupFiles implements BackupFiles {
  const PickerBackupFiles();

  /// Read off the name: the JSON backup and the CSV reading copy go through
  /// the same dialog.
  static String _mimeTypeFor(String fileName) =>
      fileName.endsWith('.csv') ? 'text/csv' : 'application/json';

  @override
  Future<bool> save(String fileName, String contents) async {
    final location = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: _mimeTypeFor(fileName),
    );

    return location != null;
  }

  @override
  Future<String?> open() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;

    // Read as bytes and decode here: the file is the user's, so it may not
    // be the UTF-8 the export wrote, and a decode failure has to surface as
    // "this is not a backup" rather than as a crash.
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}
