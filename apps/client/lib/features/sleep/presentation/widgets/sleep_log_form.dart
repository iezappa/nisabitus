import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../sleep_labels.dart';

/// The hours field for the selected day.
///
/// The button says "register" or "update" depending on whether the day
/// already holds a record, so the user knows they are about to replace it.
class SleepLogForm extends StatefulWidget {
  const SleepLogForm({
    required this.existingHours,
    required this.onSave,
    super.key,
  });

  final double? existingHours;
  final ValueChanged<double> onSave;

  @override
  State<SleepLogForm> createState() => _SleepLogFormState();
}

class _SleepLogFormState extends State<SleepLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hours = TextEditingController(
    text: widget.existingHours == null
        ? ''
        : formatHours(widget.existingHours!),
  );

  @override
  void didUpdateWidget(SleepLogForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The strip moved to another day, so the field follows the new record.
    if (oldWidget.existingHours != widget.existingHours) {
      _hours.text = widget.existingHours == null
          ? ''
          : formatHours(widget.existingHours!);
    }
  }

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(double.parse(_hours.text.replaceAll(',', '.')));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sleepLog.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _hours,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.sleepFieldHours,
                  suffixText: 'h',
                ),
                validator: (value) {
                  final hours = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  return hours == null || hours < 0 || hours > 24
                      ? l10n.sleepValidationHours
                      : null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gap.md),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  widget.existingHours == null
                      ? l10n.sleepSave
                      : l10n.sleepUpdate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
