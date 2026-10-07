enum CheatsheetFormat {
  markdown,
  text;

  static CheatsheetFormat parse(String value) => switch (value) {
    'markdown' => CheatsheetFormat.markdown,
    'text' => CheatsheetFormat.text,
    _ => CheatsheetFormat.text,
  };
}

abstract final class CheatsheetFolders {
  static const imported = 'Imported';
  static const appNotes = 'Notes';
}

class CheatsheetNote {
  const CheatsheetNote({
    required this.id,
    required this.updatedAt,
    required this.title,
    required this.content,
    required this.folder,
    required this.format,
    required this.importedAt,
    this.sourceName,
  });

  final String id;
  final DateTime updatedAt;
  final String title;
  final String content;
  final String folder;
  final String? sourceName;
  final CheatsheetFormat format;
  final DateTime importedAt;

  bool get isImported => sourceName != null;
}

class CheatsheetImportDraft {
  const CheatsheetImportDraft({
    required this.title,
    required this.content,
    required this.format,
    this.folder = CheatsheetFolders.imported,
    this.sourceName,
  });

  final String title;
  final String content;
  final String folder;
  final String? sourceName;
  final CheatsheetFormat format;
}

class CheatsheetSaveDraft {
  const CheatsheetSaveDraft({
    required this.title,
    required this.content,
    required this.folder,
    required this.format,
  });

  final String title;
  final String content;
  final String folder;
  final CheatsheetFormat format;
}
