import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/range_selector.dart';
import '../../streaks/presentation/streak_providers.dart';
import '../../streaks/presentation/streaks_progress_view.dart';
import 'habit_providers.dart';
import 'habits_progress_view.dart';

/// The progress side of the Hábitos tab: habits and streaks under one window.
///
/// Both modules read their own range provider, but the user sees a single
/// control — two selectors on one screen would be noise, not choice.
class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(habitProgressRangeProvider);

    return ListView(
      padding: const EdgeInsets.only(top: Gap.lg, bottom: 96),
      children: [
        RangeSelector(
          value: range,
          onChanged: (value) {
            ref.read(habitProgressRangeProvider.notifier).state = value;
            ref.read(streakProgressRangeProvider.notifier).state = value;
          },
        ),
        const HabitsProgressView(),
        const StreaksProgressView(),
      ],
    );
  }
}
