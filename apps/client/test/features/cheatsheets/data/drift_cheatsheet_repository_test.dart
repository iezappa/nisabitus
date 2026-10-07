import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/cheatsheets/data/drift_cheatsheet_repository.dart';
import 'package:nisabitus/features/cheatsheets/domain/cheatsheet_note.dart';

void main() {
  late AppDatabase db;
  late DriftCheatsheetRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftCheatsheetRepository(db);
  });

  tearDown(() => db.close());

  test('imports notes with record fields and source metadata', () async {
    final imported = await repository.importMany([
      const CheatsheetImportDraft(
        title: 'Riverpod',
        content: '# Providers',
        sourceName: 'riverpod.md',
        format: CheatsheetFormat.markdown,
      ),
    ]);

    expect(imported, hasLength(1));
    expect(imported.single.id, isNotEmpty);
    expect(imported.single.title, 'Riverpod');
    expect(imported.single.content, '# Providers');
    expect(imported.single.folder, CheatsheetFolders.imported);
    expect(imported.single.sourceName, 'riverpod.md');
    expect(imported.single.format, CheatsheetFormat.markdown);
    expect(imported.single.updatedAt, isA<DateTime>());
    expect(imported.single.importedAt, isA<DateTime>());
  });

  test('creates, edits, and deletes app notes', () async {
    final created = await repository.create(
      const CheatsheetSaveDraft(
        title: 'Docker commands',
        content: 'docker compose up -d',
        folder: 'Servers',
        format: CheatsheetFormat.markdown,
      ),
    );

    expect(created.sourceName, isNull);
    expect(created.folder, 'Servers');

    final updated = await repository.update(
      created.id,
      const CheatsheetSaveDraft(
        title: 'Docker compose',
        content: 'docker compose pull',
        folder: 'ZimaOS',
        format: CheatsheetFormat.markdown,
      ),
    );

    expect(updated?.title, 'Docker compose');
    expect(updated?.content, 'docker compose pull');
    expect(updated?.folder, 'ZimaOS');
    expect(updated?.updatedAt, isA<DateTime>());

    await repository.delete(created.id);

    expect(await repository.byId(created.id), isNull);
  });

  test('searches by title, folder, and content', () async {
    await repository.importMany([
      const CheatsheetImportDraft(
        title: 'SQLite',
        content: 'SELECT * FROM habits',
        format: CheatsheetFormat.text,
      ),
      const CheatsheetImportDraft(
        title: 'Dart',
        content: 'Futures and streams',
        format: CheatsheetFormat.text,
      ),
    ]);

    expect((await repository.list(query: 'sqlite')).map((note) => note.title), [
      'SQLite',
    ]);
    expect(
      (await repository.list(query: 'streams')).map((note) => note.title),
      ['Dart'],
    );
    expect(
      (await repository.list(query: 'imported')).map((note) => note.title),
      ['SQLite', 'Dart'],
    );
  });
}
