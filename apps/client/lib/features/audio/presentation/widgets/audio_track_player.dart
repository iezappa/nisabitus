import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/media/video_frame.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/audio_track.dart';

/// The chosen track, playing beside whatever it is playing beside.
///
/// Deliberately its own widget, watching nothing that ticks: the focus
/// countdown rebuilds once a second, and a player rebuilt that often would
/// be a video that restarts every second.
///
/// It does not start on its own. A browser refuses to play sound until the
/// listener has asked for it, and pretending otherwise would leave the user
/// staring at a player that looks broken; so the frame is offered with its
/// own play button and the copy says as much.
class AudioTrackPlayer extends StatelessWidget {
  const AudioTrackPlayer({required this.track, super.key});

  final AudioTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final link = track.link;

    // Null off the web, where there is no frame to put a page in.
    final frame = link != null && link.canPlayInline
        ? buildVideoFrame(link.playable)
        : null;

    final outside = _OpenOutside(url: link?.original ?? track.url);

    if (frame == null) return _OutsideOnly(outside: outside);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // The shape every video on the internet is, so the player fills
          // it instead of sitting in a letterboxed grey band.
          child: AspectRatio(
            aspectRatio: 16 / 9,
            // Keyed by the link: choosing another track replaces the
            // player rather than pointing the old one somewhere new.
            child: KeyedSubtree(key: ValueKey(link!.playable), child: frame),
          ),
        ),
        const SizedBox(height: Gap.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.audioTrackPlayHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Offered even when the frame is there. A browser can refuse to
            // show it — an old one that has never heard of a credentialless
            // frame, a video whose channel forbids embedding — and there is
            // no event that says so, so the way out is always on screen
            // rather than appearing once it is too late to help.
            outside,
          ],
        ),
      ],
    );
  }
}

/// The button that hands the link to the browser.
class _OpenOutside extends StatelessWidget {
  const _OpenOutside({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(l10n.planVideoOpen),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}

/// What is offered where there is no frame: the link itself.
class _OutsideOnly extends StatelessWidget {
  const _OutsideOnly({required this.outside});

  final Widget outside;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.planVideoExternalOnly,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: Gap.sm),
        outside,
      ],
    );
  }
}
