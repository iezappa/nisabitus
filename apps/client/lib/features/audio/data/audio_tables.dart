import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// Something the user plays while doing something else in the app: rain
/// while focusing, a bell or a guided track while meditating.
///
/// A library rather than a field on whatever is running, because what you
/// listen to and what you are doing are not the same choice: one recording
/// serves every session, and a session repeated tomorrow should not drag
/// last week's soundtrack along with it.
///
/// [usage] is which library the track belongs to. Two lists, not one with a
/// filter on it: a twenty-minute guided meditation offered as background for
/// a work sprint is not a shortcut, it is a list the user has to read past.
///
/// The link is stored exactly as pasted and read at the point of use, so a
/// row can never be a URL this build would not have accepted.
@DataClassName('AudioTrackRow')
@TableIndex(name: 'audio_track_by_usage', columns: {#usage})
class AudioTracks extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get url => text().withLength(min: 1, max: 2000)();

  /// Stored as the canonical wire name of TrackUsage.
  TextColumn get usage =>
      text().withLength(max: 16).withDefault(const Constant('FOCUS'))();
}
