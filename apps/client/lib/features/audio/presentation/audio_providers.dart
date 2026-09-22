import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/preferences/preferences.dart';
import '../data/drift_audio_track_repository.dart';
import '../domain/audio_track.dart';
import '../domain/audio_track_repository.dart';

final audioTrackRepositoryProvider = Provider<AudioTrackRepository>(
  (ref) => DriftAudioTrackRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write to either library.
final audioRevisionProvider = StateProvider<int>((ref) => 0);

/// One library, in the order the user built it.
final audioTracksProvider = FutureProvider.family<List<AudioTrack>, TrackUsage>(
  (ref, usage) {
    ref.watch(audioRevisionProvider);

    return ref.watch(audioTrackRepositoryProvider).list(usage);
  },
);

/// Which track is chosen in one library, as its id, or the empty string.
///
/// A preference rather than a column on the session or the sitting: it is a
/// property of this device and this listener, not of the work being done.
/// Someone who restores a backup on a machine with no speakers should not
/// find a track starting up because of what they listened to last month.
final chosenTrackIdProvider =
    StateNotifierProvider.family<StringPreference, String, TrackUsage>((
      ref,
      usage,
    ) {
      return StringPreference(
        ref.watch(sharedPreferencesProvider),
        '${usage.preferenceKey}.sound',
        fallback: '',
      );
    });

/// The chosen track, or null when there is none — or when the one that was
/// chosen has since been deleted.
final chosenTrackProvider = Provider.family<AudioTrack?, TrackUsage>((
  ref,
  usage,
) {
  final id = ref.watch(chosenTrackIdProvider(usage));
  if (id.isEmpty) return null;

  final tracks = ref.watch(audioTracksProvider(usage)).valueOrNull ?? const [];
  for (final track in tracks) {
    if (track.id == id) return track;
  }
  return null;
});

/// Write operations on the libraries.
class AudioTrackActions {
  AudioTrackActions(this._ref);

  final Ref _ref;

  AudioTrackRepository get _repository =>
      _ref.read(audioTrackRepositoryProvider);

  Future<void> add(AudioTrackDraft draft) async {
    final track = await _repository.add(draft);
    _invalidate();
    // Chosen straight away: someone who just went to the trouble of adding
    // a track wants to hear it, not to pick it out of a list afterwards.
    choose(draft.usage, track.id);
  }

  Future<void> update(String id, AudioTrackDraft draft) async {
    await _repository.update(id, draft);
    _invalidate();
  }

  Future<void> delete(AudioTrack track) async {
    await _repository.delete(track.id);
    if (_ref.read(chosenTrackIdProvider(track.usage)) == track.id) {
      choose(track.usage, '');
    }
    _invalidate();
  }

  void choose(TrackUsage usage, String id) =>
      _ref.read(chosenTrackIdProvider(usage).notifier).set(id);

  void _invalidate() =>
      _ref.read(audioRevisionProvider.notifier).update((v) => v + 1);
}

final audioTrackActionsProvider = Provider<AudioTrackActions>(
  AudioTrackActions.new,
);
