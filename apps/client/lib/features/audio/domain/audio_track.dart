import '../../../core/media/video_link.dart';

/// Which library a track belongs to.
enum TrackUsage {
  /// Played beside the focus timer: rain, white noise, a long album.
  focus('FOCUS', 'pomodoro'),

  /// Played while meditating: a bell, a guided sitting, silence with rain.
  meditation('MEDITATION', 'meditation');

  const TrackUsage(this.wireName, this.preferenceKey);

  /// What the column holds.
  final String wireName;

  /// The prefix of the remembered choice.
  ///
  /// `pomodoro` rather than `focus` for the first one: that key was already
  /// being written before these were two libraries, and changing it would
  /// silently unpick the sound someone had chosen.
  final String preferenceKey;

  static TrackUsage parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    for (final usage in TrackUsage.values) {
      if (usage.wireName == normalized) return usage;
    }
    return TrackUsage.focus;
  }
}

/// What the user is asking for when they add a track.
class AudioTrackDraft {
  AudioTrackDraft({
    required String name,
    required String url,
    required this.usage,
  }) : name = _validateName(name),
       url = _validateUrl(url);

  final String name;
  final String url;
  final TrackUsage usage;

  static const maxNameLength = 80;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    if (trimmed.length > maxNameLength) {
      throw ArgumentError.value(value, 'name', 'The name is too long');
    }
    return trimmed;
  }

  /// Refuses a link the app could not play.
  ///
  /// Checked when it is written down rather than when it is played: a track
  /// that turns out to be unplayable in the middle of a sitting is a worse
  /// moment to find out than the one where it was being added.
  static String _validateUrl(String value) {
    final trimmed = value.trim();
    final link = VideoLink.parse(trimmed);
    if (link == null || !link.canPlayInline) {
      throw ArgumentError.value(value, 'url', 'The link cannot be played here');
    }
    return trimmed;
  }
}

/// A track in one of the user's libraries.
///
/// Read tolerantly, unlike [AudioTrackDraft]: a row whose link this build
/// cannot make sense of — pasted by an older version, or arrived in someone
/// else's backup — is shown as one that cannot be played rather than
/// throwing on the way into a list.
class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.name,
    required this.url,
    required this.usage,
  });

  final String id;
  final String name;
  final String url;
  final TrackUsage usage;

  /// The link, read, or null when there is nothing playable in it.
  VideoLink? get link => VideoLink.parse(url);

  bool get isPlayable => link?.canPlayInline ?? false;
}
