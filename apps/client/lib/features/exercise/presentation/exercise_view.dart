import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/exercise.dart';
import 'exercise_providers.dart';
import 'widgets/exercise_form_dialog.dart';

/// The training half of the health section: the day's work, with the
/// catalogue underneath.
class ExerciseView extends ConsumerWidget {
  const ExerciseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workout = ref.watch(workoutDayProvider);
    final catalogue = ref.watch(exerciseCatalogueProvider);
    final actions = ref.read(exerciseActionsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
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
        SectionHeader(
          label: l10n.exerciseCatalogue,
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: l10n.exerciseNew,
            onPressed: () async {
              final draft = await showExerciseForm(context);
              if (draft != null) await actions.createExercise(draft);
            },
          ),
        ),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.lg,
                          0,
                          Gap.lg,
                          Gap.sm,
                        ),
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
                                if (set != null) {
                                  await actions.logSet(
                                    exercise.id,
                                    reps: set.reps,
                                    weight: set.weight,
                                  );
                                }
                              },
                            ),
                            onTap: () async {
                              final draft = await showExerciseForm(
                                context,
                                existing: exercise,
                                onDelete: () =>
                                    actions.deleteExercise(exercise.id),
                              );
                              if (draft != null) {
                                await actions.updateExercise(
                                  exercise.id,
                                  draft,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
        ),
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
