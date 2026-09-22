import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/media/video_link.dart';
import '../../../../core/media/video_frame.dart';

/// Shows the video saved on an exercise, without leaving the app where it
/// can be helped.
///
/// The link was already being saved and never shown, so this is the other
/// half of a field that has existed since v9: the point of writing down how
/// a movement is done is being able to look at it in the middle of a set.
///
/// Small on purpose. It is a reminder of the form, not a viewing session, and
/// a full-screen player over a workout list would be in the way of the thing
/// it is meant to serve.
Future<void> showExerciseVideo(BuildContext context, String url) {
  final link = VideoLink.parse(url);
  if (link == null) return Future<void>.value();

  return showDialog<void>(
    context: context,
    builder: (context) => _VideoDialog(link: link),
  );
}

class _VideoDialog extends StatelessWidget {
  const _VideoDialog({required this.link});

  final VideoLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Null off the web, where there is no frame to put a page in.
    final frame = link.canPlayInline ? buildVideoFrame(link.playable) : null;
    final width = MediaQuery.sizeOf(context).width.clamp(280.0, 560.0) - 56;

    return AlertDialog(
      title: Text(l10n.planVideoTitle),
      content: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (frame != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                // The shape every video on the internet is, so the player
                // fills it instead of sitting in a letterboxed grey band.
                child: AspectRatio(aspectRatio: 16 / 9, child: frame),
              )
            else
              Text(
                l10n.planVideoExternalOnly,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: Gap.md),
            Text(
              // Said here rather than buried in the compliance page: this app
              // claims that nothing leaves the device, and for one dialog
              // that stops being true.
              l10n.planVideoNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.planVideoOpen),
          onPressed: () => launchUrl(
            Uri.parse(link.original),
            mode: LaunchMode.externalApplication,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}
