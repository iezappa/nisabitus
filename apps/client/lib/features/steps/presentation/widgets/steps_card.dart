import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/step_log.dart';
import '../step_providers.dart';
import 'steps_form.dart';

/// The day's step count, at the top of the training screen.
///
/// Walking is the exercise that happens without being planned, so it sits
/// above the routine rather than inside it: there is no set to tick and
/// nothing scheduled, only a number that grows and gets written down.
class StepsCard extends ConsumerWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final log = ref.watch(stepsForSelectedDayProvider).valueOrNull;
    final goal = ref.watch(stepGoalProvider).valueOrNull ?? StepGoal.fallback;
    final walked = log?.steps ?? 0;
    final reached = log != null && goal.isReachedBy(walked);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showStepsForm(context, ref, existing: log),
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 20,
                      color: reached
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: Text(
                        l10n.stepsToday.toUpperCase(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    if (log != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: l10n.stepsClear,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => ref.read(stepActionsProvider).clear(),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                if (log == null)
                  Text(
                    // Not "0 steps": a day nobody wrote down is not a day of
                    // no walking, and every average in the report rests on
                    // that difference.
                    l10n.stepsNone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _grouped(walked),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: reached ? theme.colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      Text(
                        l10n.stepsOfGoal(
                          _grouped(walked),
                          _grouped(goal.steps),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                  LinearProgressIndicator(
                    value: goal.progressFor(walked),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  if (reached) ...[
                    const SizedBox(height: Gap.xs),
                    Text(
                      l10n.stepsGoalReached,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thousands separated the way they are written in Spanish.
///
/// By hand rather than through `intl`: the figure is always a plain integer
/// under six digits, and a number format carries a locale this does not need
/// to resolve.
String _grouped(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return buffer.toString();
}
