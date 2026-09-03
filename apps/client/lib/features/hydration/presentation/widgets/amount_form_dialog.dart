import 'package:flutter/material.dart';

import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks for a number of millilitres. Returns null when dismissed.
///
/// Used for both an odd-sized drink and the daily target, because both are
/// the same question — how many millilitres — and two dialogs that ask it
/// would drift apart on their validation.
Future<int?> showAmountForm(
  BuildContext context, {
  required String title,
  required int max,
  int? initial,
}) => showDialog<int>(
  context: context,
  builder: (context) =>
      _AmountFormDialog(title: title, max: max, initial: initial),
);

class _AmountFormDialog extends StatefulWidget {
  const _AmountFormDialog({
    required this.title,
    required this.max,
    this.initial,
  });

  final String title;
  final int max;
  final int? initial;

  @override
  State<_AmountFormDialog> createState() => _AmountFormDialogState();
}

class _AmountFormDialogState extends State<_AmountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.initial == null ? '' : '${widget.initial}',
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(int.parse(_amount.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(text: widget.title),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.hydrationAmount,
              suffixText: 'ml',
            ),
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              final parsed = int.tryParse((value ?? '').trim());
              return parsed == null || parsed < 1 || parsed > widget.max
                  ? l10n.hydrationValidationAmount(widget.max)
                  : null;
            },
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
}
