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

  static const _mimeType = 'application/json';

  @override
  Future<bool> save(String fileName, String contents) async {
    final location = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: _mimeType,
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
