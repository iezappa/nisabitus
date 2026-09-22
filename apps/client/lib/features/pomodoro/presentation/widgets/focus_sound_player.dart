import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/media/video_frame.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/focus_sound.dart';

/// The chosen sound, playing next to the clock.
///
/// Deliberately its own widget, watching nothing that ticks: the countdown
/// rebuilds once a second, and a player rebuilt that often would be a video
/// that restarts every second.
///
/// It does not start on its own. A browser refuses to play sound until the
/// listener has asked for it, and pretending otherwise would leave the user
/// staring at a player that looks broken; so the frame is offered with its
/// own play button and the copy says as much.
class FocusSoundPlayer extends StatelessWidget {
  const FocusSoundPlayer({required this.sound, super.key});

  final FocusSound sound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final link = sound.link;

    // Null off the web, where there is no frame to put a page in.
    final frame = link != null && link.canPlayInline
        ? buildVideoFrame(link.playable)
        : null;

    if (frame == null) {
      return _OutsideOnly(url: link?.original ?? sound.url);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // The shape every video on the internet is, so the player fills
          // it instead of sitting in a letterboxed grey band.
          child: AspectRatio(
            aspectRatio: 16 / 9,
            // Keyed by the link: choosing another sound replaces the
            // player rather than pointing the old one somewhere new.
            child: KeyedSubtree(key: ValueKey(link!.playable), child: frame),
          ),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          l10n.pomodoroSoundPlayHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// What is offered where there is no frame: the link itself.
class _OutsideOnly extends StatelessWidget {
  const _OutsideOnly({required this.url});

  final String url;

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
        TextButton.icon(
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.planVideoOpen),
          onPressed: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }
}
