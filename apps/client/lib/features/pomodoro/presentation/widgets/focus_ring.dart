import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../focus_timer.dart';

/// The countdown, drawn as a ring around the remaining time.
///
/// Two states, and the difference between them is the point: with a session
/// running the ring is drawn in the accent and the time counts; with none it
/// is grey and says nothing, because a clock showing 25:00 when nothing is
/// running looks like a timer that has stalled.
class FocusRing extends StatelessWidget {
  const FocusRing({
    required FocusTimerState this.state,
    required this.label,
    super.key,
  });

  /// The ring with no session behind it.
  const FocusRing.idle({required this.label, super.key}) : state = null;

  /// Null when nothing is running.
  final FocusTimerState? state;

  /// The cycle counter shown under the clock.
  final String label;

  static String format(Duration remaining) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// What an idle clock shows instead of a time.
  static const idleTime = '--:--';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final running = state;
    final isFocus = running?.phase == TimerPhase.focus;

    final colour = switch (running) {
      null => theme.colorScheme.outlineVariant,
      // The break is drawn in a lighter tone so a glance tells the two
      // phases apart without reading the label.
      _ when isFocus => theme.colorScheme.primary,
      _ => theme.colorScheme.primary.withValues(alpha: 0.45),
    };
    final ink = running == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: _RingPainter(
          progress: running?.progress ?? 0,
          // The ring behind the arc takes the accent as well, faintly. With
          // a plain grey track a session that has just started — no arc
          // drawn yet — looks exactly like no session at all, and picking
          // one has to be visible from the first second.
          track: running == null
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.primary.withValues(alpha: 0.18),
          colour: colour,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (running == null)
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              else
                Text(
                  (isFocus ? l10n.pomodoroPhaseFocus : l10n.pomodoroPhaseRest)
                      .toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              const SizedBox(height: Gap.sm),
              Text(
                running == null ? idleTime : format(running.remaining),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: Gap.sm),
              Padding(
                // Kept inside the circle: the cycle counter is a few
                // characters, but the idle line is a sentence and would
                // otherwise run out over the ring it sits in.
                padding: const EdgeInsets.symmetric(horizontal: Gap.xxl),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.colour,
    required this.track,
  });

  final double progress;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(centre, radius, base);

    final arc = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colour != colour;
}
