import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import 'cheatsheet_tables.dart';
import '../domain/cheatsheet_note.dart';
import '../domain/cheatsheet_repository.dart';

class DriftCheatsheetRepository implements CheatsheetRepository {
  DriftCheatsheetRepository(this._db);

  final AppDatabase _db;

  @override
  Future<CheatsheetNote?> byId(String id) async {
    final row = await (_db.select(
      _db.cheatsheetNotes,
    )..where((note) => note.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<CheatsheetNote> create(CheatsheetSaveDraft draft) async {
    final now = DateTime.now();
    final row = await _db
        .into(_db.cheatsheetNotes)
        .insertReturning(
          CheatsheetNotesCompanion.insert(
            title: _cleanTitle(draft.title),
            content: draft.content,
            folder: Value(
              _cleanFolder(draft.folder, CheatsheetFolders.appNotes),
            ),
            format: draft.format.name,
            importedAt: now,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.cheatsheetNotes,
    )..where((note) => note.id.equals(id))).go();
  }

  @override
  Future<List<CheatsheetNote>> importMany(
    List<CheatsheetImportDraft> drafts,
  ) async {
    if (drafts.isEmpty) return const [];

    final now = DateTime.now();
    return _db.transaction(() async {
      final imported = <CheatsheetNote>[];
      for (final draft in drafts) {
        final row = await _db
            .into(_db.cheatsheetNotes)
            .insertReturning(
              CheatsheetNotesCompanion.insert(
                title: _cleanTitle(draft.title),
                content: draft.content,
                folder: Value(
                  _cleanFolder(draft.folder, CheatsheetFolders.imported),
                ),
                sourceName: Value(draft.sourceName),
                format: draft.format.name,
                importedAt: now,
              ),
            );
        imported.add(_toDomain(row));
      }
      return imported;
    });
  }

  @override
  Future<List<CheatsheetNote>> list({String query = ''}) =>
      _query(query).get().then((rows) => rows.map(_toDomain).toList());

  @override
  Future<CheatsheetNote?> update(String id, CheatsheetSaveDraft draft) async {
    await (_db.update(
      _db.cheatsheetNotes,
    )..where((note) => note.id.equals(id))).writeTouched(
      CheatsheetNotesCompanion(
        title: Value(_cleanTitle(draft.title)),
        content: Value(draft.content),
        folder: Value(_cleanFolder(draft.folder, CheatsheetFolders.appNotes)),
        format: Value(draft.format.name),
      ),
    );
    return byId(id);
  }

  @override
  Stream<List<CheatsheetNote>> watch({String query = ''}) =>
      _query(query).watch().map((rows) => rows.map(_toDomain).toList());

  SimpleSelectStatement<CheatsheetNotes, CheatsheetNoteRow> _query(
    String query,
  ) {
    final statement = _db.select(_db.cheatsheetNotes)
      ..orderBy([
        (note) => OrderingTerm.asc(note.folder),
        (note) => OrderingTerm.desc(note.updatedAt),
      ]);

    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      final pattern =
          '%${trimmed.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      statement.where(
        (note) =>
            note.title.like(pattern) |
            note.content.like(pattern) |
            note.folder.like(pattern),
      );
    }

    return statement;
  }

  CheatsheetNote _toDomain(CheatsheetNoteRow row) => CheatsheetNote(
    id: row.id,
    updatedAt: row.updatedAt,
    title: row.title,
    content: row.content,
    folder: row.folder,
    sourceName: row.sourceName,
    format: CheatsheetFormat.parse(row.format),
    importedAt: row.importedAt,
  );

  String _cleanTitle(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Untitled note' : trimmed;
  }

  String _cleanFolder(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
