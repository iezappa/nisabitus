import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'date_range.dart';

/// The day the week strip is pointing at.
///
/// Shared by sleep and journal on purpose: the spec has both screens reload
/// for the same day when the strip moves, so they read one selection rather
/// than drifting apart.
final selectedDayProvider = StateProvider<DateTime>(
  (ref) => dateOnly(DateTime.now()),
);

/// Today, injectable so tests are not tied to the machine clock.
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));
