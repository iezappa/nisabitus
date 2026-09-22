import 'audio_track.dart';

/// The user's libraries of things to listen to.
abstract interface class AudioTrackRepository {
  /// One library, in the order the user built it.
  Future<List<AudioTrack>> list(TrackUsage usage);

  Future<AudioTrack> add(AudioTrackDraft draft);

  Future<AudioTrack> update(String id, AudioTrackDraft draft);

  Future<void> delete(String id);
}
