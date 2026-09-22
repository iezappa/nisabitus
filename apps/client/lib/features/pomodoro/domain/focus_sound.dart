import '../../../core/media/video_link.dart';

/// What the user is asking for when they add a sound.
class FocusSoundDraft {
  FocusSoundDraft({required String name, required String url})
    : name = _validateName(name),
      url = _validateUrl(url);

  final String name;
  final String url;

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
  /// Checked when it is written down rather than when it is played: a sound
  /// that turns out to be unplayable in the middle of a focus session is a
  /// worse moment to find out than the one where it was being added.
  static String _validateUrl(String value) {
    final trimmed = value.trim();
    final link = VideoLink.parse(trimmed);
    if (link == null || !link.canPlayInline) {
      throw ArgumentError.value(value, 'url', 'The link cannot be played here');
    }
    return trimmed;
  }
}

/// A sound in the user's library.
///
/// Read tolerantly, unlike [FocusSoundDraft]: a row whose link this build
/// cannot make sense of — pasted by an older version, or arrived in someone
/// else's backup — is shown as one that cannot be played rather than
/// throwing on the way into a list.
class FocusSound {
  const FocusSound({required this.id, required this.name, required this.url});

  final String id;
  final String name;
  final String url;

  /// The link, read, or null when there is nothing playable in it.
  VideoLink? get link => VideoLink.parse(url);

  bool get isPlayable => link?.canPlayInline ?? false;
}
