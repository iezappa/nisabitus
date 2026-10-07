import 'package:file_picker/file_picker.dart';

import '../domain/cheatsheet_files.dart';

class PickerCheatsheetFiles implements CheatsheetFiles {
  const PickerCheatsheetFiles();

  @override
  Future<List<CheatsheetFile>> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown', 'txt'],
    );

    return [
      for (final file in files)
        CheatsheetFile(name: file.name, bytes: await file.readAsBytes()),
    ];
  }
}
