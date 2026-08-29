import 'package:flutter/material.dart';

/// Keeps a column of content at a readable width, centred on the page.
///
/// On a desktop window a full-width list stretches a card to a metre wide
/// and the eye loses the line it was reading. Capping the measure and
/// centring what is left is what makes the same screen work on a phone and
/// on a monitor without two layouts.
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    required this.child,
    this.maxWidth = 640,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
