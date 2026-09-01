import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/medication.dart';
import 'medication_providers.dart';
import 'widgets/medication_form_dialog.dart';

/// The medication half of the health section: what is due today on top, the
/// full list underneath.
class MedicationView extends ConsumerWidget {
  const MedicationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final day = ref.watch(medicationDayProvider);
    final catalogue = ref.watch(medicationCatalogueProvider);
    final actions = ref.read(medicationActionsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        day.when(
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
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                label: l10n.medsToday,
                trailing: data.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: Gap.md),
                        child: Text(
                          l10n.medsTakenCount(data.taken, data.total),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
              ),
              if (data.isEmpty)
                EmptyState(
                  icon: Icons.medication_outlined,
                  title: l10n.medsNoneActive,
                  hint: l10n.medsNoneActiveHint,
                )
              else
                for (final status in data.statuses)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.lg,
                      0,
                      Gap.lg,
                      Gap.sm,
                    ),
                    child: Card(
                      child: CheckboxListTile(
                        value: status.taken,
                        onChanged: (_) => actions.toggle(status.medication.id),
                        title: Text(status.medication.name),
                        subtitle: status.medication.summary.isEmpty
                            ? null
                            : Text(status.medication.summary),
                        secondary: _KindGlyph(kind: status.medication.kind),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        SectionHeader(
          label: l10n.medsCatalogue,
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: l10n.medsNew,
            onPressed: () async {
              final draft = await showMedicationForm(context);
              if (draft != null) await actions.create(draft);
            },
          ),
        ),
        catalogue.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.medication_liquid_outlined,
                  title: l10n.medsEmpty,
                  hint: l10n.medsEmptyHint,
                )
              : Column(
                  children: [
                    for (final medication in items)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.lg,
                          0,
                          Gap.lg,
                          Gap.sm,
                        ),
                        child: Opacity(
                          // A paused entry stays visible but recedes: it is
                          // history, not something to do today.
                          opacity: medication.active ? 1 : 0.55,
                          child: Card(
                            child: ListTile(
                              leading: _KindGlyph(kind: medication.kind),
                              title: Text(medication.name),
                              subtitle: Text(
                                [
                                  medication.kind == MedicationKind.medication
                                      ? l10n.medsKindMedication
                                      : l10n.medsKindSupplement,
                                  if (medication.summary.isNotEmpty)
                                    medication.summary,
                                ].join(' · '),
                              ),
                              onTap: () async {
                                final draft = await showMedicationForm(
                                  context,
                                  existing: medication,
                                  onDelete: () => actions.delete(medication.id),
                                );
                                if (draft != null) {
                                  await actions.update(medication.id, draft);
                                }
                              },
                            ),
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

/// Tells the two kinds apart at a glance without spelling it out twice.
class _KindGlyph extends StatelessWidget {
  const _KindGlyph({required this.kind});

  final MedicationKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        kind == MedicationKind.medication
            ? Icons.medication_outlined
            : Icons.eco_outlined,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
