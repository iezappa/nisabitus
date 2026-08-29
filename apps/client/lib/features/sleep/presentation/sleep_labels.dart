import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/sleep_log.dart';

/// Maps the derived sleep quality to the words and the colour that carry it.
extension SleepLabels on AppLocalizations {
  String qualityName(SleepQuality quality) => switch (quality) {
    SleepQuality.optimal => sleepQualityOptimal,
    SleepQuality.acceptable => sleepQualityAcceptable,
    SleepQuality.poor => sleepQualityPoor,
  };
}

/// The traffic light the spec asks for, resolved against the theme so it
/// still reads in the dark scheme.
Color qualityColor(BuildContext context, SleepQuality quality) {
  final scheme = Theme.of(context).colorScheme;

  return switch (quality) {
    SleepQuality.optimal => scheme.primary,
    SleepQuality.acceptable => const Color(0xFFB08A2E),
    SleepQuality.poor => scheme.error,
  };
}

/// Hours without a trailing zero: 7.5 stays 7.5, 8.0 reads as 8.
String formatHours(double hours) =>
    hours == hours.roundToDouble() ? '${hours.round()}' : '$hours';
