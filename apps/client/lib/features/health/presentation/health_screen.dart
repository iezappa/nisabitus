import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/disclaimer.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../core/widgets/week_date_selector.dart';
import '../../../l10n/app_localizations.dart';
import '../../exercise/presentation/exercise_view.dart';
import '../../medication/presentation/medication_view.dart';
import '../../nutrition/presentation/nutrition_view.dart';
import '../../sleep/presentation/sleep_view.dart';

/// The Salud tab: sleep, nutrition, training and medication for one chosen
/// day.
///
/// The week strip lives here rather than inside each view, because all four
/// answer the same question about the same day and moving it once should
/// move all of them. The notice sits in the app bar for the same reason: it
/// applies to everything under this tab.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedDayProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(l10n.tabHealth),
        actions: const [DisclaimerButton(), SizedBox(width: Gap.xs)],
      ),
      body: Column(
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
              Tab(text: l10n.healthExercise),
              Tab(text: l10n.healthMeds),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                SleepView(),
                NutritionView(),
                ExerciseView(),
                MedicationView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
