import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks for a single non-empty name. Returns null when dismissed.
Future<String?> promptForName(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) => showDialog<String>(
  context: context,
  builder: (context) => _NamePromptDialog(title: title, initialValue: initialValue),
);

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({required this.title, required this.initialValue});

  final String title;
  final String initialValue;

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
      title: Text(widget.title),
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
