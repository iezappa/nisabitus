import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A first-level tab of the app.
enum AppTab {
  dashboard('/panel', Icons.dashboard_outlined, Icons.dashboard),
  habits('/habitos', Icons.checklist_outlined, Icons.checklist),
  journal('/journal', Icons.menu_book_outlined, Icons.menu_book),
  sleep('/sueno', Icons.bedtime_outlined, Icons.bedtime),
  pomodoro('/pomodoro', Icons.timer_outlined, Icons.timer),
  todo('/todo', Icons.task_alt_outlined, Icons.task_alt),
  settings('/ajustes', Icons.settings_outlined, Icons.settings);

  const AppTab(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.dashboard => l10n.tabDashboard,
    AppTab.habits => l10n.tabHabits,
    AppTab.journal => l10n.tabJournal,
    AppTab.sleep => l10n.tabSleep,
    AppTab.pomodoro => l10n.tabPomodoro,
    AppTab.todo => l10n.tabTodo,
    AppTab.settings => l10n.tabSettings,
  };
}
