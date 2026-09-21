import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/project.dart';
import '../todo_labels.dart';

/// How a project's work stands, as one dot in the tree.
///
/// A ring rather than a filled circle: the colour answers "is anything
/// wrong", the fill answers "how far along is it", and both questions are
/// worth asking at a glance. A solid dot would have had to pick one.
///
/// The tally covers the subprojects too, so a branch nobody has expanded
/// still says that something under it is late.
class ProjectDot extends StatelessWidget {
  const ProjectDot({required this.tally, super.key});

  final ProjectTally tally;

  /// Big enough to read a colour off, small enough to sit in a dense tile.
  static const diameter = 18.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final health = tally.health;
    final color = projectHealthColor(context, health);

    return Tooltip(
      message: tally.total == 0
          ? l10n.projectHealthName(health)
          : '${l10n.projectHealthName(health)} · '
                '${l10n.todoProjectProgress(tally.done, tally.total)}',
      child: SizedBox.square(
        dimension: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The track, so an empty project still reads as a project rather
            // than as a missing icon.
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 2.5,
              color: color.withValues(alpha: 0.18),
            ),
            if (tally.total > 0)
              CircularProgressIndicator(
                value: tally.progress,
                strokeWidth: 2.5,
                color: color,
                // The ring is decoration over a figure that is already in the
                // subtitle; announcing it again would read the same project
                // twice.
                semanticsLabel: null,
              ),
            if (health == ProjectHealth.allDone)
              Icon(Icons.check, size: 10, color: color),
          ],
        ),
      ),
    );
  }
}
