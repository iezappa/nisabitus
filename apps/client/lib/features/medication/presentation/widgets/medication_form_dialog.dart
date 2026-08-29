import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/medication.dart';
import '../../domain/medication_repository.dart';

/// Collects one medication or supplement. Returns null when dismissed.
Future<MedicationDraft?> showMedicationForm(
  BuildContext context, {
  Medication? existing,
  Future<void> Function()? onDelete,
}) => showDialog<MedicationDraft>(
  context: context,
  builder: (context) =>
      _MedicationFormDialog(existing: existing, onDelete: onDelete),
);

class _MedicationFormDialog extends StatefulWidget {
  const _MedicationFormDialog({this.existing, this.onDelete});

  final Medication? existing;
  final Future<void> Function()? onDelete;

  @override
  State<_MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<_MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _dose = TextEditingController(text: widget.existing?.dose ?? '');
  late final _schedule = TextEditingController(
    text: widget.existing?.schedule ?? '',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');

  late MedicationKind _kind =
      widget.existing?.kind ?? MedicationKind.fallback;
  late bool _active = widget.existing?.active ?? true;

  @override
  void dispose() {
    for (final c in [_name, _dose, _schedule, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      MedicationDraft(
        name: _name.text,
        kind: _kind,
        dose: _text(_dose),
        schedule: _text(_schedule),
        notes: _text(_notes),
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null ? l10n.medsNew : l10n.medsEdit,
        deleteLabel: widget.existing?.name,
        onDelete: widget.onDelete,
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 255,
                  decoration: InputDecoration(labelText: l10n.fieldName),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.validationNameRequired
                      : null,
                ),
                const SizedBox(height: Gap.sm),
                SegmentedButton<MedicationKind>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: MedicationKind.medication,
                      label: Text(l10n.medsKindMedication),
                    ),
                    ButtonSegment(
                      value: MedicationKind.supplement,
                      label: Text(l10n.medsKindSupplement),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: Gap.lg),
                // Free text on purpose: the app records what the user was
                // told, it does not compute or check a regimen.
                TextFormField(
                  controller: _dose,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: l10n.medsDose,
                    hintText: l10n.medsDoseHint,
                  ),
                ),
                TextFormField(
                  controller: _schedule,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: l10n.medsSchedule,
                    hintText: l10n.medsScheduleHint,
                  ),
                ),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: l10n.medsNotes),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.medsActive),
                  subtitle: Text(l10n.medsInactiveHint),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
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
