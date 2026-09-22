import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/save_failure.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/audio_track.dart';
import '../audio_providers.dart';
import 'audio_track_dialog.dart';
import 'audio_track_player.dart';

/// One library, picked from and played: the whole feature in one widget.
///
/// Mounted by the focus timer and by meditation, which want exactly the
/// same thing in the same shape. Each passes its own [usage] and gets its
/// own list — a twenty-minute guided sitting offered as background for a
/// work sprint is not a shortcut, it is a line the user has to read past.
class AudioTrackSection extends ConsumerWidget {
  const AudioTrackSection({required this.usage, this.title, super.key});

  final TrackUsage usage;

  /// The section heading. Defaults to the shared "Sonido".
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(label: title ?? l10n.audioTrack),
        _Picker(usage: usage),
        _Player(usage: usage),
      ],
    );
  }
}

/// Which track is playing, and the ways to change that.
class _Picker extends ConsumerWidget {
  const _Picker({required this.usage});

  final TrackUsage usage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(audioTrackActionsProvider);
    final tracks =
        ref.watch(audioTracksProvider(usage)).valueOrNull ?? const [];
    final chosen = ref.watch(chosenTrackProvider(usage));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: chosen?.id ?? '',
              decoration: InputDecoration(labelText: l10n.audioTrack),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.audioTrackNone)),
                for (final track in tracks)
                  DropdownMenuItem(value: track.id, child: Text(track.name)),
              ],
              onChanged: (value) => actions.choose(usage, value ?? ''),
            ),
          ),
          const SizedBox(width: Gap.sm),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.audioTrackAdd,
            onPressed: () async {
              final draft = await showAudioTrackForm(context, usage: usage);
              if (draft == null || !context.mounted) return;
              await reportSaveFailure(context, () => actions.add(draft));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.audioTrackEdit,
            // Only what is playing can be edited: a library of three rain
            // recordings does not need a screen of its own, and the one in
            // the dropdown is the one the user is thinking about.
            onPressed: chosen == null
                ? null
                : () => _edit(context, ref, chosen),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AudioTrack track,
  ) async {
    final actions = ref.read(audioTrackActionsProvider);
    final draft = await showAudioTrackForm(
      context,
      usage: usage,
      existing: track,
      onDelete: () => actions.delete(track),
    );
    if (draft == null || !context.mounted) return;
    await reportSaveFailure(context, () => actions.update(track.id, draft));
  }
}

/// The player, watching only the choice — never whatever is counting.
class _Player extends ConsumerWidget {
  const _Player({required this.usage});

  final TrackUsage usage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final chosen = ref.watch(chosenTrackProvider(usage));
    final library =
        ref.watch(audioTracksProvider(usage)).valueOrNull ?? const [];

    if (chosen == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
        child: Text(
          library.isEmpty ? l10n.audioTrackLibraryEmpty : l10n.audioTrackNone,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
      child: AudioTrackPlayer(track: chosen),
    );
  }
}
