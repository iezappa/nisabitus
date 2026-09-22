/// What can be done with a video link the user saved.
///
/// The link is whatever the user pasted, so it is read here rather than
/// trusted: a YouTube watch page cannot be put in a frame, but the same video
/// can. Anything this cannot recognise is still openable — it just opens
/// where links open, outside the app.
///
/// In core because two modules paste links now: an exercise showing how a
/// movement is done, and a focus session playing rain while it runs. Neither
/// owns the other, and the rules for reading a URL are the same either way.
enum VideoKind {
  /// A page that can be shown inside the app.
  embeddable,

  /// A file a browser can play on its own — an `.mp4` on a server somewhere.
  file,

  /// Recognised as a link and nothing more.
  external,
}

/// A video link, read.
class VideoLink {
  const VideoLink._(this.original, this.kind, this.playable);

  /// Reads [url], or returns null when there is no usable link in it.
  ///
  /// Null is not an error to report: a record with no video is the normal
  /// case, and so is one whose field holds something that is not a link.
  static VideoLink? parse(String? url) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || !uri.isScheme('https')) {
      // http is refused as well as nonsense. A page served over http cannot
      // be framed by a page served over https, so accepting it would only
      // produce a viewer that is permanently blank.
      return null;
    }

    if (_youtubeId(uri) case final id?) {
      // `youtube-nocookie.com` rather than `youtube.com`: it is YouTube's own
      // privacy-preserving host and it sets no tracking cookie unless the
      // video is actually played. This app tells the user it does not track
      // them, and embedding the ordinary player would quietly make that less
      // true the moment a card was opened.
      return VideoLink._(
        raw,
        VideoKind.embeddable,
        'https://www.youtube-nocookie.com/embed/$id',
      );
    }

    if (_vimeoId(uri) case final id?) {
      return VideoLink._(
        raw,
        VideoKind.embeddable,
        'https://player.vimeo.com/video/$id',
      );
    }

    if (_isVideoFile(uri)) return VideoLink._(raw, VideoKind.file, raw);

    return VideoLink._(raw, VideoKind.external, raw);
  }

  /// The link exactly as the user saved it, for opening outside the app.
  final String original;

  final VideoKind kind;

  /// What to put in the viewer: the embed page, or the file itself.
  ///
  /// Equal to [original] for a link this cannot do better with, in which case
  /// nothing frames it and only the external button is offered.
  final String playable;

  /// Whether the app can show this without leaving it.
  bool get canPlayInline => kind != VideoKind.external;

  /// The video id of a YouTube link, whichever of its four shapes it is in.
  ///
  /// `watch?v=`, `youtu.be/`, `shorts/` and `embed/` all name the same video
  /// and the user pastes whichever one their browser gave them.
  static String? _youtubeId(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    final segments = uri.pathSegments;

    if (host == 'youtu.be') {
      return segments.isEmpty ? null : _cleanId(segments.first);
    }

    if (host != 'youtube.com' &&
        host != 'm.youtube.com' &&
        host != 'youtube-nocookie.com') {
      return null;
    }

    if (uri.queryParameters['v'] case final id? when id.isNotEmpty) {
      return _cleanId(id);
    }
    if (segments.length >= 2 &&
        (segments.first == 'embed' || segments.first == 'shorts')) {
      return _cleanId(segments[1]);
    }

    return null;
  }

  static String? _vimeoId(Uri uri) {
    if (uri.host.toLowerCase().replaceFirst('www.', '') != 'vimeo.com') {
      return null;
    }

    final first = uri.pathSegments.firstOrNull;
    // Numeric, because vimeo.com also serves channels and user pages and
    // neither of those is a video.
    return first != null && int.tryParse(first) != null ? first : null;
  }

  /// Ids are letters, digits, dash and underscore. Anything else means the
  /// link was not what it looked like, and a bad id makes a blank frame.
  static String? _cleanId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{5,32}$').hasMatch(value) ? value : null;

  static bool _isVideoFile(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.ogv') ||
        path.endsWith('.ogg');
  }
}
