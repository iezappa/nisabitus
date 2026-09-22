import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/database/uuid.dart';
import '../domain/audio_track.dart';
import '../domain/audio_track_repository.dart';

/// Drift-backed implementation of [AudioTrackRepository].
class DriftAudioTrackRepository implements AudioTrackRepository {
  DriftAudioTrackRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<AudioTrack>> list(TrackUsage usage) async {
    // In the order they were added, which is the order the user built the
    // list in — alphabetical would reshuffle it under them every time they
    // renamed one.
    final rows =
        await (_db.select(_db.audioTracks)
              ..where((t) => t.usage.equals(usage.wireName))
              ..orderBy([(t) => OrderingTerm.asc(t.rowId)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<AudioTrack> add(AudioTrackDraft draft) async {
    final id = newUuid();
    await _db
        .into(_db.audioTracks)
        .insert(
          AudioTracksCompanion.insert(
            id: Value(id),
            name: draft.name,
            url: draft.url,
            usage: Value(draft.usage.wireName),
          ),
        );

    return AudioTrack(
      id: id,
      name: draft.name,
      url: draft.url,
      usage: draft.usage,
    );
  }

  @override
  Future<AudioTrack> update(String id, AudioTrackDraft draft) async {
    await (_db.update(
      _db.audioTracks,
    )..where((t) => t.id.equals(id))).writeTouched(
      AudioTracksCompanion(
        name: Value(draft.name),
        url: Value(draft.url),
        usage: Value(draft.usage.wireName),
      ),
    );

    return AudioTrack(
      id: id,
      name: draft.name,
      url: draft.url,
      usage: draft.usage,
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.audioTracks)..where((t) => t.id.equals(id))).go();
  }

  AudioTrack _toDomain(AudioTrackRow row) => AudioTrack(
    id: row.id,
    name: row.name,
    url: row.url,
    usage: TrackUsage.parse(row.usage),
  );
}
