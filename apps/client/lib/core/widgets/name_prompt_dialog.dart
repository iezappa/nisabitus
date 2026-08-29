import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'dialog_title.dart';

/// Asks for a single non-empty name. Returns null when dismissed.
///
/// Pass [onDelete] to put a bin in the corner: every editing modal in the
/// app offers the same way out, so the user never has to hunt for where
/// deleting lives this time.
Future<String?> promptForName(
  BuildContext context, {
  required String title,
  String initialValue = '',
  Future<void> Function()? onDelete,
  String? deleteLabel,
}) => showDialog<String>(
  context: context,
  builder: (context) => _NamePromptDialog(
    title: title,
    initialValue: initialValue,
    onDelete: onDelete,
    deleteLabel: deleteLabel ?? initialValue,
  ),
);

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({
    required this.title,
    required this.initialValue,
    required this.deleteLabel,
    this.onDelete,
  });

  final String title;
  final String initialValue;
  final String deleteLabel;
  final Future<void> Function()? onDelete;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.title,
        deleteLabel: widget.deleteLabel,
        onDelete: widget.onDelete,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 255,
          decoration: InputDecoration(labelText: l10n.fieldName),
          validator: (value) => (value ?? '').trim().isEmpty
              ? l10n.validationNameRequired
              : null,
          onFieldSubmitted: (_) => _submit(),
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
}
