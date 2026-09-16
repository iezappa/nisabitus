import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../backup_feedback.dart';
import '../backup_providers.dart';

/// "Delete all my data", the last row of Your data.
class EraseAllDataTile extends StatelessWidget {
  const EraseAllDataTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.delete_forever_outlined, color: error),
      title: Text(l10n.eraseAllData, style: TextStyle(color: error)),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => const _EraseAllDataDialog(),
      ),
    );
  }
}

/// Asks for a typed word, not just a tap.
///
/// A second button in the same place is a confirmation a thumb gets through
/// by accident. Typing a word cannot be done without reading the dialog, and
/// this is the one action in the app with no way back.
class _EraseAllDataDialog extends ConsumerStatefulWidget {
  const _EraseAllDataDialog();

  @override
  ConsumerState<_EraseAllDataDialog> createState() =>
      _EraseAllDataDialogState();
}

class _EraseAllDataDialogState extends ConsumerState<_EraseAllDataDialog> {
  final _typed = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _exportFirst() async {
    setState(() => _busy = true);
    try {
      final outcome = await ref.read(backupActionsProvider).export();
      if (!mounted) return;
      showBackupOutcome(
        context,
        outcome,
        succeeded: (l10n, rows) => l10n.backupExported(rows),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _erase() async {
    setState(() => _busy = true);
    try {
      await ref.read(eraseAllDataActionsProvider).eraseEverything();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final word = l10n.eraseAllConfirmWord;
    final confirmed = _typed.text.trim().toUpperCase() == word;

    return AlertDialog(
      title: Text(l10n.eraseAllTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.eraseAllBody),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _typed,
              enabled: !_busy,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.eraseAllTypeToConfirm(word),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _exportFirst,
          child: Text(l10n.eraseAllExportFirst),
        ),
        FilledButton(
          onPressed: _busy || !confirmed ? null : _erase,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(l10n.eraseAllAction),
        ),
      ],
    );
  }
}
