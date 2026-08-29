import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets a horizontal list be scrolled with an ordinary mouse wheel.
///
/// A horizontal [Scrollable] reads `scrollDelta.dx`, and a wheel only
/// produces `dy`, so it registers no handler and the list never moves. On a
/// desktop window that leaves anything past the right edge unreachable.
///
/// The vertical delta is translated here and claimed through the pointer
/// signal resolver, so the surrounding vertical list does not scroll instead.
/// Mouse dragging is enabled too, for trackpads and for grabbing the band.
class WheelScrollArea extends StatefulWidget {
  const WheelScrollArea({required this.child, this.controller, super.key});

  final Widget child;

  /// Supply one to share it with a scrollbar; otherwise it is owned here.
  final ScrollController? controller;

  @override
  State<WheelScrollArea> createState() => WheelScrollAreaState();
}

class WheelScrollAreaState extends State<WheelScrollArea> {
  ScrollController? _owned;

  ScrollController get controller =>
      widget.controller ?? (_owned ??= ScrollController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!controller.hasClients) return;

    final delta = event.scrollDelta.dy;
    if (delta == 0) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final position = controller.position;
      controller.jumpTo(
        (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _onPointerSignal,
    child: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: widget.child,
    ),
  );
}
