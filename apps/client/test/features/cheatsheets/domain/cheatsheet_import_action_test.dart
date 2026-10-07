import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/cheatsheets/domain/cheatsheet_files.dart';
import 'package:nisabitus/features/cheatsheets/domain/cheatsheet_note.dart';
import 'package:nisabitus/features/cheatsheets/domain/cheatsheet_repository.dart';
import 'package:nisabitus/features/cheatsheets/domain/markdown_speech.dart';

void main() {
  test('strips markdown syntax before speech', () {
    expect(
      speechTextFromMarkdown('''# Title
- one `code`
```dart
final ignored = true;
```
[link](https://example.com)'''),
      'Title. one code. link',
    );
  });

  test('imports picked markdown and text files as UTF-8 notes', () async {
    final repository = _FakeCheatsheetRepository();
    final action = CheatsheetImportAction(
      files: _FakeCheatsheetFiles([
        CheatsheetFile(
          name: 'riverpod.md',
          bytes: Uint8List.fromList(utf8.encode('# Riverpod')),
        ),
        CheatsheetFile(
          name: 'broken.txt',
          bytes: Uint8List.fromList([...utf8.encode('hola'), 0xff]),
        ),
      ]),
      repository: repository,
    );

    await action.importPicked();

    expect(repository.drafts, hasLength(2));
    expect(repository.drafts.first.title, 'riverpod');
    expect(repository.drafts.first.sourceName, 'riverpod.md');
    expect(repository.drafts.first.format, CheatsheetFormat.markdown);
    expect(repository.drafts.first.content, '# Riverpod');
    expect(repository.drafts.last.title, 'broken');
    expect(repository.drafts.last.format, CheatsheetFormat.text);
    expect(repository.drafts.last.content, contains('hola'));
  });
}

class _FakeCheatsheetFiles implements CheatsheetFiles {
  const _FakeCheatsheetFiles(this.files);

  final List<CheatsheetFile> files;

  @override
  Future<List<CheatsheetFile>> pick() async => files;
}

class _FakeCheatsheetRepository implements CheatsheetRepository {
  final drafts = <CheatsheetImportDraft>[];

  @override
  Future<CheatsheetNote?> byId(String id) async => null;

  @override
  Future<List<CheatsheetNote>> importMany(
    List<CheatsheetImportDraft> drafts,
  ) async {
    this.drafts.addAll(drafts);
    return [
      for (final (index, draft) in drafts.indexed)
        CheatsheetNote(
          id: '$index',
          updatedAt: DateTime(2026),
          title: draft.title,
          content: draft.content,
          folder: draft.folder,
          format: draft.format,
          importedAt: DateTime(2026),
          sourceName: draft.sourceName,
        ),
    ];
  }

  @override
  Future<CheatsheetNote> create(CheatsheetSaveDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<List<CheatsheetNote>> list({String query = ''}) async => const [];

  @override
  Future<CheatsheetNote?> update(String id, CheatsheetSaveDraft draft) async =>
      throw UnimplementedError();

  @override
  Stream<List<CheatsheetNote>> watch({String query = ''}) =>
      const Stream.empty();
}
