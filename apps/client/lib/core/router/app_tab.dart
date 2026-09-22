import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A first-level tab of the app.
///
/// Settings is deliberately absent: it is reachable from every screen and
/// lives outside this set, so hiding tabs can never lock the user out of the
/// screen that unhides them.
///
/// Meditation is absent too, and for a different reason: it is a sub-tab of
/// Salud, where it sits with sleep, food and training — all answers to the
/// same question about the same day. Its old path still resolves, from the
/// redirect in the router.
enum AppTab {
  dashboard('/panel', Icons.dashboard_outlined, Icons.dashboard),
  habits('/habitos', Icons.checklist_outlined, Icons.checklist),
  journal('/journal', Icons.menu_book_outlined, Icons.menu_book),
  health('/salud', Icons.favorite_outline, Icons.favorite),
  pomodoro('/pomodoro', Icons.timer_outlined, Icons.timer),
  todo('/todo', Icons.task_alt_outlined, Icons.task_alt);

  const AppTab(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.dashboard => l10n.tabDashboard,
    AppTab.habits => l10n.tabHabits,
    AppTab.journal => l10n.tabJournal,
    AppTab.health => l10n.tabHealth,
    AppTab.pomodoro => l10n.tabPomodoro,
    AppTab.todo => l10n.tabTodo,
  };
}
