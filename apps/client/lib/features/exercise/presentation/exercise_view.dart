import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/time/weekday_labels.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../discipline/presentation/discipline_section.dart';
import '../domain/exercise.dart';
import '../domain/scheduled_exercise.dart';
import 'exercise_providers.dart';
import 'widgets/exercise_form_dialog.dart';
import 'widgets/scheduled_exercise_dialog.dart';

/// The movements this app knows about, folded away by default.
///
/// It is a reference list, not a day's work: useful when writing something
/// down, noise the rest of the time. It stays shut and says how many it holds,
/// so a closed section still tells you something.
class _CatalogueSection extends ConsumerStatefulWidget {
  const _CatalogueSection();

  @override
  ConsumerState<_CatalogueSection> createState() => _CatalogueSectionState();
}

class _CatalogueSectionState extends ConsumerState<_CatalogueSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final actions = ref.read(exerciseActionsProvider);
    final catalogue = ref.watch(exerciseCatalogueProvider);
    final count = catalogue.valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          label: l10n.exerciseCatalogue,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$count', style: theme.textTheme.bodySmall),
              IconButton(
                icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
                tooltip: _open ? l10n.actionCollapse : l10n.actionExpand,
                onPressed: () => setState(() => _open = !_open),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: l10n.exerciseNew,
                onPressed: () async {
                  final draft = await showExerciseForm(context);
                  if (draft == null) return;

                  await actions.createExercise(draft);
                  // Opened on the way in: something was just added, and a
                  // list that stays shut after you add to it looks broken.
                  setState(() => _open = true);
                },
              ),
            ],
          ),
        ),
        if (_open)
          catalogue.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.list_alt_outlined,
                    title: l10n.exerciseNoneYet,
                    hint: l10n.exerciseNoneYetHint,
                  )
                : Column(
                    children: [
                      for (final exercise in items)
                        _CatalogueRow(exercise: exercise),
                    ],
                  ),
          ),
      ],
    );
  }
}

/// One movement in the catalogue, and the ways into it.
class _CatalogueRow extends ConsumerWidget {
  const _CatalogueRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(exerciseActionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: Card(
        child: ListTile(
          title: Text(exercise.name),
          subtitle: exercise.muscleGroup == null
              ? null
              : Text(exercise.muscleGroup!),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.exerciseAddSet,
            onPressed: () async {
              final set = await showSetForm(context);
              if (set == null) return;

              await actions.logSet(
                exercise.id,
                reps: set.reps,
                weight: set.weight,
                note: set.note,
              );
            },
          ),
          onTap: () async {
            final draft = await showExerciseForm(
              context,
              existing: exercise,
              onDelete: () => actions.deleteExercise(exercise.id),
            );
            if (draft != null) await actions.updateExercise(exercise.id, draft);
          },
        ),
      ),
    );
  }
}

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
  /// An empty catalogue is not a dead end: the form can write down a movement
  /// it does not have yet and carry on with it.
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

/// The training half of the health section: the day's work, with the
/// The training half of the health section: the day's work, with the
/// catalogue underneath.
class ExerciseView extends ConsumerWidget {
  const ExerciseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workout = ref.watch(workoutDayProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const _PlanSection(),
        SectionHeader(label: l10n.exerciseWorkout),
        workout.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              '$error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (day) => day.isEmpty
              ? EmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: l10n.exerciseNoSets,
                  hint: l10n.exerciseNoSetsHint,
                )
              : _Workout(day: day),
        ),
        const DisciplineSection(),
        const _CatalogueSection(),
      ],
    );
  }
}

class _Workout extends ConsumerWidget {
  const _Workout({required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(exerciseActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.exerciseTotalSets,
                  value: '${day.totalSets}',
                  icon: Icons.repeat,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: StatTile(
                  label: l10n.exerciseTotalReps,
                  value: '${day.totalReps}',
                  icon: Icons.numbers,
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: StatTile(
                  label: l10n.exerciseVolume,
                  value: l10n.exerciseVolumeValue(
                    day.totalVolume.toStringAsFixed(0),
                  ),
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        for (final block in day.blocks)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            block.exercise.name,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (block.topWeight case final top?)
                          Text(
                            l10n.exerciseTopWeight(top.toStringAsFixed(0)),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        for (final set in block.sets)
                          ActionChip(
                            label: Text(
                              set.weight == null
                                  ? l10n.exerciseSetLine(set.reps)
                                  : l10n.exerciseSetLineWeighted(
                                      set.reps,
                                      set.weight!.toStringAsFixed(
                                        set.weight! % 1 == 0 ? 0 : 1,
                                      ),
                                    ),
                            ),
                            onPressed: () async {
                              final edited = await showSetForm(
                                context,
                                existing: set,
                                onDelete: () => actions.deleteSet(set.id),
                              );
                              if (edited != null) {
                                await actions.updateSet(
                                  set.id,
                                  reps: edited.reps,
                                  weight: edited.weight,
                                  note: edited.note,
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
