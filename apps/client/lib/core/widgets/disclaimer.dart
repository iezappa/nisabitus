import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The one place the health notice is written.
///
/// Every screen that touches food, training, sleep or medication points at
/// this, so the wording can never drift between them.
Future<void> showHealthDisclaimer(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(l10n.disclaimerTitle, textAlign: TextAlign.center),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Text(
            l10n.disclaimerBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.disclaimerAction),
        ),
      ],
    ),
  );
}

/// The question mark that opens the notice.
///
/// Present on every screen that records health data, so the boundary between
/// a log and a diagnosis is never more than one tap away from where the user
/// is entering numbers.
class DisclaimerButton extends StatelessWidget {
  const DisclaimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: l10n.disclaimerTooltip,
      onPressed: () => showHealthDisclaimer(context),
    );
  }
}

/// The notice as it appears in settings, where there is room to state it
/// rather than hide it behind an icon.
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    l10n.disclaimerTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Text(
              l10n.settingsDisclaimerShort,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Gap.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => showHealthDisclaimer(context),
                child: Text(l10n.settingsDisclaimerRead),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
