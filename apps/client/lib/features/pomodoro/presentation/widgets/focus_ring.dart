import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../focus_timer.dart';

/// The countdown, drawn as a ring around the remaining time.
class FocusRing extends StatelessWidget {
  const FocusRing({required this.state, required this.label, super.key});

  final FocusTimerState state;

  /// The cycle counter shown under the clock.
  final String label;

  static String format(Duration remaining) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isFocus = state.phase == TimerPhase.focus;

    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: _RingPainter(
          progress: state.progress,
          track: theme.colorScheme.outlineVariant,
          // The break is drawn in a lighter tone so a glance tells the two
          // phases apart without reading the label.
          colour: isFocus
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.45),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (isFocus ? l10n.pomodoroPhaseFocus : l10n.pomodoroPhaseRest)
                    .toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                format(state.remaining),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: Gap.sm),
              Text(label, style: theme.textTheme.bodySmall),
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
