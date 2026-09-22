import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/audio_track.dart';

/// Collects one track for a library. Returns null when dismissed.
Future<AudioTrackDraft?> showAudioTrackForm(
  BuildContext context, {
  required TrackUsage usage,
  AudioTrack? existing,
  Future<void> Function()? onDelete,
}) => showDialog<AudioTrackDraft>(
  context: context,
  builder: (context) =>
      _AudioTrackDialog(usage: usage, existing: existing, onDelete: onDelete),
);

class _AudioTrackDialog extends StatefulWidget {
  const _AudioTrackDialog({required this.usage, this.existing, this.onDelete});

  /// Which library the track lands in. Not asked of the user: they are
  /// standing in the module it belongs to.
  final TrackUsage usage;

  final AudioTrack? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_AudioTrackDialog> createState() => _AudioTrackDialogState();
}

class _AudioTrackDialogState extends State<_AudioTrackDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _url = TextEditingController(text: widget.existing?.url ?? '');

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      AudioTrackDraft(name: _name.text, url: _url.text, usage: widget.usage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null
            ? l10n.audioTrackAdd
            : l10n.audioTrackEdit,
        deleteLabel: widget.existing?.name,
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: AudioTrackDraft.maxNameLength,
                decoration: InputDecoration(
                  labelText: l10n.audioTrackName,
                  helperText: l10n.audioTrackNameHint,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.validationNameRequired
                    : null,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.audioTrackUrl,
                  helperText: l10n.audioTrackUrlHint,
                ),
                // Checked here rather than when it is played: finding out
                // the link is unusable in the middle of a focus session is
                // a worse moment than the one where it was pasted.
                validator: (value) =>
                    _playable(value) ? null : l10n.audioTrackInvalid,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                l10n.audioTrackNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }

  /// Whether the draft would accept this link, asked without throwing.
  static bool _playable(String? value) {
    try {
      AudioTrackDraft(name: 'x', url: value ?? '', usage: TrackUsage.focus);
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
