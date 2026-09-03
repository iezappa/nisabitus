import 'package:flutter/material.dart';

/// The app's mark, as it appears in the navigation rail.
///
/// Painted in a single colour rather than shipped as a second image: the
/// artwork has one source of truth, and a tint cannot drift out of sync with
/// it the way a hand-exported white copy would.
///
/// `srcIn` is what makes that work — it replaces the colour of every pixel
/// the mark actually covers and leaves the transparent ones alone, so the
/// shape survives and only its ink changes.
class BrandLogo extends StatelessWidget {
  const BrandLogo({required this.color, this.height = 28, super.key});

  /// The ink the mark is painted in.
  final Color color;

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/logo.png',
    height: height,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    // The mark carries no meaning a screen reader needs: the rail beside it
    // names every destination, and the app's name is in the title bar.
    excludeFromSemantics: true,
  );
}
