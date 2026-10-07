import 'cheatsheet_note.dart';

abstract interface class CheatsheetRepository {
  Future<List<CheatsheetNote>> list({String query = ''});

  Stream<List<CheatsheetNote>> watch({String query = ''});

  Future<CheatsheetNote?> byId(String id);

  Future<List<CheatsheetNote>> importMany(List<CheatsheetImportDraft> drafts);

  Future<CheatsheetNote> create(CheatsheetSaveDraft draft);

  Future<CheatsheetNote?> update(String id, CheatsheetSaveDraft draft);

  Future<void> delete(String id);
}
