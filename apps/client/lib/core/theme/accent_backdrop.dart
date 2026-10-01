import 'package:flutter/material.dart';

/// The accent-tinted page behind the whole app.
///
/// Scaffolds, app bars and navigation surfaces are transparent so one wash can
/// sit under the full shell instead of each screen painting its own rectangle.
class AccentBackdrop extends StatelessWidget {
  const AccentBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = theme.colorScheme.surface;
    final tint = tintedPage(
      page,
      theme.colorScheme.primary,
      dark: theme.brightness == Brightness.dark,
    );

    return Material(
      color: page,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.75],
            colors: [tint, page],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.1, 1.0),
              radius: 1.2,
              colors: [tint.withValues(alpha: 0.85), tint.withValues(alpha: 0)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The page mixed with the accent without materially changing page contrast.
Color tintedPage(Color page, Color accent, {required bool dark}) {
  final mixed = HSLColor.fromColor(
    Color.alphaBlend(accent.withValues(alpha: 0.55), page),
  );
  final lightness = HSLColor.fromColor(page).lightness;
  final lift = dark ? 0.09 : -0.045;

  return mixed.withLightness((lightness + lift).clamp(0.0, 1.0)).toColor();
}
