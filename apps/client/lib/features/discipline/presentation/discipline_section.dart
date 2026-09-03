import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/time/weekday_labels.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/discipline.dart';
import 'discipline_providers.dart';
import 'widgets/discipline_dialog.dart';

/// What was practised for a time on the chosen day.
///
/// Its own section rather than a row among the exercises: a swim and a squat
/// are not the same kind of thing, and a list that mixes "4x6 · 90 kg" with
/// "45 min · 2 km" makes the reader do the sorting.
class DisciplineSection extends ConsumerWidget {
  const DisciplineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final disciplines = ref.watch(disciplinesForDayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          label: l10n.discipline,
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: l10n.disciplineAdd,
            onPressed: () => _openForm(context, ref),
          ),
        ),
        disciplines.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.directions_run_outlined,
                  title: l10n.disciplineEmpty,
                  hint: l10n.disciplineHint,
                )
              : Column(
                  children: [
                    for (final item in items)
                      _DisciplineRow(
                        discipline: item,
                        onEdit: () => _openForm(context, ref, existing: item),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Discipline? existing,
  }) async {
    final actions = ref.read(disciplineActionsProvider);
    final day = ref.read(selectedDayProvider);

    final result = await showDisciplineForm(
      context,
      day: day,
      existing: existing,
      onDelete: existing == null ? null : () => actions.delete(existing.id),
    );
    if (result == null) return;

    if (existing == null) {
      await actions.schedule(result.draft, recurrence: result.recurrence);
    } else {
      await actions.update(existing.id, result.draft);
    }
  }
}

/// One session: what to do, whether it is done, and how it went.
class _DisciplineRow extends ConsumerWidget {
  const _DisciplineRow({required this.discipline, required this.onEdit});

  final Discipline discipline;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final summary = [
      l10n.disciplineMinutes(discipline.durationMinutes),
      if (discipline.distanceKm case final km?) l10n.disciplineKm(_km(km)),
      if (discipline.isRecurring && discipline.repeatDays.isNotEmpty)
        l10n.planRepeatSummary(l10n.weekdayList(discipline.repeatDays)),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: discipline.completed,
            onChanged: (value) => value ?? false
                ? _complete(context, ref)
                : ref.read(disciplineActionsProvider).reopen(discipline.id),
          ),
          title: Text(
            discipline.name,
            style: discipline.completed
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
              if (discipline.notes case final notes?) Text(notes),
              if (discipline.feedback case final feedback?)
                Text(
                  feedback,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          isThreeLine: discipline.notes != null || discipline.feedback != null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (discipline.isRecurring)
                IconButton(
                  icon: const Icon(Icons.event_busy_outlined, size: 20),
                  tooltip: l10n.planStopRepeat,
                  onPressed: () => _stopRepeating(context, ref),
                ),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                tooltip: l10n.disciplineEdit,
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two and a half kilometres reads as 2.5, twenty as 20 — not 20.0.
  String _km(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final completion = await showDisciplineCompletion(
      context,
      discipline: discipline,
    );
    if (completion == null) return;

    await ref
        .read(disciplineActionsProvider)
        .complete(discipline.id, completion);
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

    await ref.read(disciplineActionsProvider).stopRecurrence(discipline.id);
  }
}
