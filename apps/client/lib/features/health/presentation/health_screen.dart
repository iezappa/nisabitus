import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/centered_content.dart';
import '../../../core/widgets/disclaimer.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../core/widgets/week_date_selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../exercise/presentation/exercise_progress_view.dart';
import '../../exercise/presentation/exercise_view.dart';
import '../../hydration/presentation/hydration_progress_view.dart';
import '../../hydration/presentation/hydration_view.dart';
import '../../medication/presentation/medication_progress_view.dart';
import '../../medication/presentation/medication_view.dart';
import '../../nutrition/presentation/nutrition_progress_view.dart';
import '../../nutrition/presentation/nutrition_view.dart';
import '../../sleep/presentation/sleep_progress_view.dart';
import '../../sleep/presentation/sleep_view.dart';

/// The Salud tab: sleep, eating, water, training and medication for one
/// chosen day.
///
/// The week strip lives here rather than inside each view, because all four
/// answer the same question about the same day and moving it once should
/// move all of them. The notice sits in the app bar for the same reason: it
/// applies to everything under this tab.
///
/// The progress toggle does not: each sub-tab has its own list and its own
/// figures, so switching Sueño to progress must leave Ejercicio where the
/// user left it.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with SingleTickerProviderStateMixin {
  static const _views = [
    (list: SleepView(), progress: SleepProgressView()),
    (list: NutritionView(), progress: NutritionProgressView()),
    (list: HydrationView(), progress: HydrationProgressView()),
    (list: ExerciseView(), progress: ExerciseProgressView()),
    (list: MedicationView(), progress: MedicationProgressView()),
  ];

  late final TabController _tabs = TabController(
    length: _views.length,
    vsync: this,
  )..addListener(() => setState(() {}));

  /// One flag per sub-tab, so each remembers which side it was left on.
  final _showingProgress = List.filled(_views.length, false);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedDayProvider);
    final current = _tabs.index;

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(l10n.tabHealth),
        actions: [
          const DisclaimerButton(),
          ProgressToggle(
            showingProgress: _showingProgress[current],
            onChanged: (value) =>
                setState(() => _showingProgress[current] = value),
          ),
          const SizedBox(width: Gap.xs),
        ],
      ),
      body: CenteredContent(
        child: Column(
          children: [
            WeekDateSelector(
              selected: selected,
              today: ref.watch(todayProvider),
              onSelected: (day) =>
                  ref.read(selectedDayProvider.notifier).state = day,
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                Tab(text: l10n.healthSleep),
                Tab(text: l10n.healthNutrition),
                Tab(text: l10n.hydration),
                Tab(text: l10n.healthExercise),
                Tab(text: l10n.healthMeds),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (var i = 0; i < _views.length; i++)
                    _showingProgress[i] ? _views[i].progress : _views[i].list,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
