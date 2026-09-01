import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/theme/app_theme.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';

/// Relative luminance, per the WCAG definition.
double _luminance(Color c) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours, from 1 to 21.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);

  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final schemes = {
    'light': [for (final a in AccentColor.values) AppTheme.light(a)],
    'dark': [for (final a in AccentColor.values) AppTheme.dark(a)],
  };

  group('body text stays readable', () {
    test('on the page background, in both schemes', () {
      schemes.forEach((name, themes) {
        for (final theme in themes) {
          final ratio = _contrast(
            theme.colorScheme.onSurface,
            theme.scaffoldBackgroundColor,
          );
          expect(
            ratio,
            greaterThan(7),
            reason:
                '$name: text on the page reads at '
                '${ratio.toStringAsFixed(1)}:1',
          );
        }
      });
    });

    test('on a card, which sits above the page', () {
      schemes.forEach((name, themes) {
        for (final theme in themes) {
          final ratio = _contrast(
            theme.colorScheme.onSurface,
            theme.cardTheme.color!,
          );
          expect(
            ratio,
            greaterThan(7),
            reason:
                '$name: text on a card reads at '
                '${ratio.toStringAsFixed(1)}:1',
          );
        }
      });
    });
  });

  test('muted text still clears the readable threshold', () {
    schemes.forEach((name, themes) {
      for (final theme in themes) {
        final ratio = _contrast(
          theme.colorScheme.onSurfaceVariant,
          theme.cardTheme.color!,
        );
        expect(
          ratio,
          greaterThan(4.5),
          reason: '$name: muted text reads at ${ratio.toStringAsFixed(1)}:1',
        );
      }
    });
  });

  group('every accent works in both schemes', () {
    test('carries readable text on a filled button', () {
      for (final accent in AccentColor.values) {
        for (final theme in [AppTheme.light(accent), AppTheme.dark(accent)]) {
          final ratio = _contrast(
            theme.colorScheme.onPrimary,
            theme.colorScheme.primary,
          );
          expect(
            ratio,
            greaterThan(3),
            reason:
                '${accent.id}: label on the accent reads at '
                '${ratio.toStringAsFixed(1)}:1',
          );
        }
      }
    });

    test('stands out against the surface it sits on', () {
      for (final accent in AccentColor.values) {
        for (final theme in [AppTheme.light(accent), AppTheme.dark(accent)]) {
          final ratio = _contrast(
            theme.colorScheme.primary,
            theme.cardTheme.color!,
          );
          expect(
            ratio,
            greaterThan(3),
            reason:
                '${accent.id}: accent on a card reads at '
                '${ratio.toStringAsFixed(1)}:1',
          );
        }
      }
    });
  });

  group('the dark scheme keeps its shape', () {
    test('cards sit above the page rather than merging into it', () {
      for (final accent in AccentColor.values) {
        final theme = AppTheme.dark(accent);
        expect(
          theme.cardTheme.color,
          isNot(theme.scaffoldBackgroundColor),
          reason: 'a card that matches the page has no edge',
        );
      }
    });

    test('the ground is off black, not pure black', () {
      // Pure black under warm paper reads as a different product; the dark
      // scheme is meant to be the same paper at night.
      final ground = AppTheme.dark(AccentColor.forest).scaffoldBackgroundColor;

      expect(ground, isNot(const Color(0xFF000000)));
      expect(_luminance(ground), lessThan(0.02));
    });

    test('stays neutral so nothing competes with the accent', () {
      // Colour belongs to the accent. A tinted ground reads as a second
      // colour and muddies whichever accent the user picked.
      for (final theme in [
        AppTheme.dark(AccentColor.forest),
        AppTheme.light(AccentColor.forest),
      ]) {
        final ground = theme.scaffoldBackgroundColor;
        final channels = [ground.r, ground.g, ground.b];
        final spread = channels.reduce(math.max) - channels.reduce(math.min);

        expect(
          spread,
          lessThan(0.04),
          reason: 'the ground carries a colour cast of $spread',
        );
      }
    });

    test('hairlines are visible without being loud', () {
      for (final accent in AccentColor.values) {
        final theme = AppTheme.dark(accent);
        final ratio = _contrast(
          theme.colorScheme.outlineVariant,
          theme.cardTheme.color!,
        );

        expect(
          ratio,
          greaterThan(1.1),
          reason: '${accent.id}: border invisible',
        );
        expect(ratio, lessThan(3), reason: '${accent.id}: border shouts');
      }
    });
  });
}
