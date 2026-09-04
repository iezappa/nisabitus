import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/time/weekday_labels.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../discipline/presentation/discipline_section.dart';
import '../domain/exercise.dart';
import '../domain/scheduled_exercise.dart';
import 'exercise_providers.dart';
import 'widgets/exercise_form_dialog.dart';
import 'widgets/scheduled_exercise_dialog.dart';

/// What is written down for the day, ready to be ticked off.
///
/// One row per exercise per day, which is both the plan and the record.
/// Nothing here compares a day against a separate routine: a repetition was
/// written down as its own days when it was created, so correcting one of
/// them corrects that day and no other.
class _PlanSection extends ConsumerWidget {
  const _PlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheduled = ref.watch(scheduledExercisesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          label: l10n.planToday,
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: l10n.planAdd,
            onPressed: () => _openForm(context, ref),
          ),
        ),
        scheduled.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.event_note_outlined,
                  title: l10n.planEmpty,
                  hint: l10n.planEmptyHint,
                )
              : Column(
                  children: [
                    for (final item in items)
                      _ScheduledRow(
                        scheduled: item,
                        onEdit: () => _openForm(context, ref, existing: item),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Opens the one form this section has.
  ///
  /// An empty catalogue is not a dead end, and neither is a wrong one: the
  /// form can write down a movement it does not have yet, correct the name,
  /// muscle group or video of the one that is selected, and delete one that
  /// should never have been written down. Those are the three things the
  /// catalogue section used to be for.
  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ScheduledExercise? existing,
  }) async {
    final actions = ref.read(exerciseActionsProvider);
    final day = ref.read(selectedDayProvider);
    final catalogue = await ref.read(exerciseRepositoryProvider).exercises();
    if (!context.mounted) return;

    final result = await showScheduledExerciseForm(
      context,
      catalogue: catalogue,
      day: day,
      existing: existing,
      onDelete: existing == null
          ? null
          : () => actions.deleteScheduled(existing.id),
      onCreateExercise: () async {
        final draft = await showExerciseForm(context);

        return draft == null ? null : actions.createExercise(draft);
      },
      onEditExercise: (exercise) async {
        // The form pops with no draft both when it is dismissed and when the
        // movement is deleted from it, so deletion is remembered here rather
        // than inferred from the absence of a draft.
        var deleted = false;
        final draft = await showExerciseForm(
          context,
          existing: exercise,
          onDelete: () async {
            deleted = true;
            await actions.deleteExercise(exercise.id);
          },
        );
        if (deleted) return const ExerciseRemoved();
        if (draft == null) return null;

        await actions.updateExercise(exercise.id, draft);

        // Rebuilt here rather than re-read: the form validated the draft on
        // the way out, and the dialog needs the corrected name now, not
        // after a round trip.
        return ExerciseCorrected(
          Exercise(
            id: exercise.id,
            name: draft.name,
            description: draft.description,
            muscleGroup: draft.muscleGroup,
            videoUrl: draft.videoUrl,
          ),
        );
      },
    );
    if (result == null) return;

    if (existing == null) {
      await actions.schedule(result.draft, recurrence: result.recurrence);
    } else {
      await actions.updateScheduled(existing.id, result.draft);
    }
  }
}

/// One exercise on the day: what to do, whether it is done, and how it went.
class _ScheduledRow extends ConsumerWidget {
  const _ScheduledRow({required this.scheduled, required this.onEdit});

  final ScheduledExercise scheduled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final catalogue = ref.watch(exerciseCatalogueProvider).valueOrNull;
    final name = catalogue
        ?.where((exercise) => exercise.id == scheduled.exerciseId)
        .firstOrNull
        ?.name;

    final summary = [
      l10n.planSetsReps(scheduled.sets, scheduled.reps),
      if (scheduled.weightKg case final weight?)
        l10n.planWeight(weight.toStringAsFixed(0)),
      if (scheduled.rpe case final rpe?) l10n.planRpe(rpe),
      if (scheduled.isRecurring && scheduled.repeatDays.isNotEmpty)
        l10n.planRepeatSummary(l10n.weekdayList(scheduled.repeatDays)),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: scheduled.completed,
            onChanged: (value) => value ?? false
                ? _complete(context, ref)
                : ref.read(exerciseActionsProvider).reopen(scheduled.id),
          ),
          title: Text(
            name ?? '',
            style: scheduled.completed
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary),
              if (scheduled.comments case final comments?) Text(comments),
              if (scheduled.feedback case final feedback?)
                Text(
                  feedback,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          isThreeLine: scheduled.comments != null || scheduled.feedback != null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (scheduled.isRecurring)
                IconButton(
                  icon: const Icon(Icons.event_busy_outlined, size: 20),
                  tooltip: l10n.planStopRepeat,
                  onPressed: () => _stopRepeating(context, ref),
                ),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                tooltip: l10n.planEdit,
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ticking it off asks what actually happened. Whatever is left blank
  /// stands as planned, which is the common case and should cost one tap.
  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final completion = await showCompletionForm(context, scheduled: scheduled);
    if (completion == null) return;

    await ref.read(exerciseActionsProvider).complete(scheduled.id, completion);
  }

  Future<void> _stopRepeating(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: l10n.planStopRepeatTitle,
      body: l10n.planStopRepeatBody,
      confirmLabel: l10n.planStopRepeat,
    );
    if (!confirmed) return;

    await ref.read(exerciseActionsProvider).stopRecurrence(scheduled.id);
  }
}

/// The training half of the health section: the gym routine for the day,
/// and the disciplines practised for a time rather than counted in sets.
///
/// There is no catalogue section here any more. It was a reference list, not
/// a day's work, and the one place it was needed — picking a movement — is
/// inside the routine's own form, which can also write a new one down,
/// correct one that is wrong, and delete one that should not be there.
class ExerciseView extends ConsumerWidget {
  const ExerciseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.only(bottom: 96),
    children: const [_PlanSection(), DisciplineSection()],
  );
}
