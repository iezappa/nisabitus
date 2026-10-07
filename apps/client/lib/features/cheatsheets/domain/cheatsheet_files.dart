import 'dart:convert';
import 'dart:typed_data';

import 'cheatsheet_note.dart';
import 'cheatsheet_repository.dart';

class CheatsheetFile {
  const CheatsheetFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class CheatsheetFiles {
  Future<List<CheatsheetFile>> pick();
}

class CheatsheetImportAction {
  const CheatsheetImportAction({required this.files, required this.repository});

  final CheatsheetFiles files;
  final CheatsheetRepository repository;

  Future<List<CheatsheetNote>> importPicked() async {
    final files = await this.files.pick();
    if (files.isEmpty) return const [];

    return repository.importMany([
      for (final file in files)
        CheatsheetImportDraft(
          title: _titleFrom(file.name),
          content: utf8.decode(file.bytes, allowMalformed: true),
          sourceName: file.name,
          format: _formatFrom(file.name),
        ),
    ]);
  }

  static String _titleFrom(String name) {
    final slash = name.lastIndexOf(RegExp(r'[\\/]'));
    final fileName = slash < 0 ? name : name.substring(slash + 1);
    final dot = fileName.lastIndexOf('.');
    final title = dot <= 0 ? fileName : fileName.substring(0, dot);
    return title.trim().isEmpty ? fileName : title.trim();
  }

  static CheatsheetFormat _formatFrom(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
      return CheatsheetFormat.markdown;
    }
    return CheatsheetFormat.text;
  }
}
