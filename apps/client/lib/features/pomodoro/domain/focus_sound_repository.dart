import 'focus_sound.dart';

/// The user's library of things to listen to while focusing.
abstract interface class FocusSoundRepository {
  /// Every sound, in the order they were added.
  Future<List<FocusSound>> list();

  Future<FocusSound> add(FocusSoundDraft draft);

  Future<FocusSound> update(String id, FocusSoundDraft draft);

  Future<void> delete(String id);
}
