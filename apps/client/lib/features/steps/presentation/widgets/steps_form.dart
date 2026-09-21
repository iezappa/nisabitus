import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dialog_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/step_log.dart';
import '../step_providers.dart';

/// Asks for the day's step count, and lets the target be changed with it.
///
/// Both in one dialog because they are read together: the number only means
/// something against the target, and the moment the user notices the target
/// is wrong is the moment they are looking at it.
Future<void> showStepsForm(
  BuildContext context,
  WidgetRef ref, {
  StepLog? existing,
}) async {
  final goal = await ref.read(stepGoalProvider.future);
  if (!context.mounted) return;

  final result = await showDialog<({int steps, int goal})>(
    context: context,
    builder: (context) => _StepsForm(existing: existing, goal: goal),
  );
  if (result == null) return;

  final actions = ref.read(stepActionsProvider);
  if (result.goal != goal.steps) await actions.saveGoal(result.goal);
  await actions.save(result.steps);
}

class _StepsForm extends StatefulWidget {
  const _StepsForm({required this.existing, required this.goal});

  final StepLog? existing;
  final StepGoal goal;

  @override
  State<_StepsForm> createState() => _StepsFormState();
}

class _StepsFormState extends State<_StepsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _steps = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.steps}',
  );
  late final _goal = TextEditingController(text: '${widget.goal.steps}');

  @override
  void dispose() {
    _steps.dispose();
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String? validate(String? value) {
      final parsed = int.tryParse((value ?? '').trim());
      return parsed == null || parsed < 0 || parsed > maxDailySteps
          ? l10n.stepsValidation('$maxDailySteps')
          : null;
    }

    return AlertDialog(
      title: DialogTitle(
        text: widget.existing == null ? l10n.stepsRecord : l10n.stepsEdit,
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _steps,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.stepsToday),
                validator: validate,
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _goal,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.stepsGoal),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  // A target of zero is reached by standing still, which
                  // would make the whole figure meaningless.
                  return parsed == null || parsed <= 0 || parsed > maxDailySteps
                      ? l10n.stepsValidation('$maxDailySteps')
                      : null;
                },
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
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              steps: int.parse(_steps.text.trim()),
              goal: int.parse(_goal.text.trim()),
            ));
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
