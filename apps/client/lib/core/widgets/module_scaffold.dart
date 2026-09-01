import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'centered_content.dart';
import 'disclaimer.dart';
import 'settings_button.dart';

/// The frame every module wears.
///
/// One way in to settings, one way to switch between doing and reviewing,
/// and the same icon for it everywhere — a module that invents its own
/// arrangement makes the user relearn the app on every tab.
class ModuleScaffold extends StatefulWidget {
  const ModuleScaffold({
    required this.title,
    required this.list,
    required this.progress,
    this.actions = const [],
    this.header,
    this.listOnly,
    this.floatingActionButton,
    this.healthDisclaimer = false,
    this.listMaxWidth = CenteredContent.readingMeasure,
    super.key,
  });

  final String title;

  /// Where the user does the work.
  final Widget list;

  /// Where the user looks back at it.
  final Widget progress;

  /// Extra app bar actions, before the shared ones.
  final List<Widget> actions;

  /// Shown above both sides, such as a week strip.
  final Widget? header;

  /// Shown above the list only, such as a filter row.
  final Widget? listOnly;

  /// Hidden while reviewing: creating belongs to the doing side.
  final Widget? floatingActionButton;

  /// Adds the health notice, for screens that record health data.
  final bool healthDisclaimer;

  /// How wide the doing side may grow.
  ///
  /// The reading measure by default, like everywhere else. A module whose
  /// layout is panes rather than a column of cards — To-Do's project tree
  /// beside its board — passes [double.infinity] and keeps the window.
  /// Reviewing is always a column of figures, so it is capped regardless.
  final double listMaxWidth;

  @override
  State<ModuleScaffold> createState() => _ModuleScaffoldState();
}

class _ModuleScaffoldState extends State<ModuleScaffold> {
  bool _showingProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(widget.title),
        actions: [
          ...widget.actions,
          if (widget.healthDisclaimer) const DisclaimerButton(),
          ProgressToggle(
            showingProgress: _showingProgress,
            onChanged: (value) => setState(() => _showingProgress = value),
          ),
          const SizedBox(width: Gap.xs),
        ],
      ),
      floatingActionButton: _showingProgress
          ? null
          : widget.floatingActionButton,
      body: CenteredContent(
        maxWidth: _showingProgress
            ? CenteredContent.readingMeasure
            : widget.listMaxWidth,
        child: Column(
          children: [
            ?widget.header,
            if (!_showingProgress) ?widget.listOnly,
            Expanded(child: _showingProgress ? widget.progress : widget.list),
          ],
        ),
      ),
    );
  }
}

/// The one control that switches a module between doing and reviewing.
///
/// Same icon, same place, same tooltip on every screen.
class ProgressToggle extends StatelessWidget {
  const ProgressToggle({
    required this.showingProgress,
    required this.onChanged,
    super.key,
  });

  final bool showingProgress;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: Icon(showingProgress ? Icons.format_list_bulleted : Icons.insights),
      tooltip: showingProgress ? l10n.habitsList : l10n.habitsProgress,
      onPressed: () => onChanged(!showingProgress),
    );
  }
}
