import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../time/progress_range.dart';

/// The window picker shared by every progress view.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ProgressRange value;
  final ValueChanged<ProgressRange> onChanged;

  static String labelFor(AppLocalizations l10n, ProgressRange range) =>
      switch (range) {
        ProgressRange.day => l10n.rangeDay,
        ProgressRange.week => l10n.rangeWeek,
        ProgressRange.month => l10n.rangeMonth,
        ProgressRange.year => l10n.rangeYear,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: SegmentedButton<ProgressRange>(
        showSelectedIcon: false,
        segments: [
          for (final range in ProgressRange.values)
            ButtonSegment(value: range, label: Text(labelFor(l10n, range))),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
