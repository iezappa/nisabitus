import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/selected_day_provider.dart';
import '../../../../core/widgets/save_failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/vacation.dart';
import '../vacation_providers.dart';
import 'vacation_form_dialog.dart';

/// Holiday mode: the switch, and the breaks already written down.
///
/// The switch is the everyday case — away now, back at some point — and the
/// list underneath is what makes the mode worth anything afterwards: a break
/// can be written down for a trip that already happened, and the streak it
/// interrupted stops counting that gap against the user.
class VacationCard extends ConsumerWidget {
  const VacationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(vacationActionsProvider);
    final open = ref.watch(openVacationProvider);
    final today = ref.watch(todayProvider);
    final periods = ref.watch(vacationPeriodsProvider);
    final format = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsVacationHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: Gap.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: open != null,
          title: Text(l10n.vacationSwitch),
          subtitle: Text(
            open == null
                ? l10n.vacationSwitchHint
                : l10n.vacationActiveSince(format.format(open.start)),
          ),
          onChanged: (value) =>
              reportSaveFailure(context, value ? actions.start : actions.end),
        ),
        const SizedBox(height: Gap.sm),
        periods.when(
          // Nothing while it loads. The list is a handful of rows out of a
          // local store, so a spinner here would be a flash rather than
          // information — and an indeterminate one animates for ever, which
          // is a screen that never settles.
          loading: () => const SizedBox.shrink(),
          error: (error, _) =>
              Text('$error', style: TextStyle(color: theme.colorScheme.error)),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.isEmpty)
                Text(l10n.vacationEmpty, style: theme.textTheme.bodySmall)
              else
                for (final period in data)
                  _PeriodRow(period: period, format: format),
              const SizedBox(height: Gap.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.vacationAdd),
                onPressed: () async {
                  final draft = await showVacationForm(context, today: today);
                  if (draft == null || !context.mounted) return;
                  await reportSaveFailure(context, () => actions.add(draft));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodRow extends ConsumerWidget {
  const _PeriodRow({required this.period, required this.format});

  final VacationPeriod period;
  final DateFormat format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(vacationActionsProvider);
    final today = ref.watch(todayProvider);

    final end = period.endsOn;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.beach_access_outlined),
      title: Text(
        end == null
            ? l10n.vacationOpenRange(format.format(period.start))
            : l10n.vacationRange(
                format.format(period.start),
                format.format(end),
              ),
      ),
      subtitle: Text(
        [l10n.vacationLength(period.lengthBy(today)), ?period.note].join(' · '),
      ),
      onTap: () async {
        final draft = await showVacationForm(
          context,
          today: today,
          existing: period,
          onDelete: () => actions.delete(period.id),
        );
        if (draft == null || !context.mounted) return;
        await reportSaveFailure(
          context,
          () => actions.update(period.id, draft),
        );
      },
    );
  }
}
