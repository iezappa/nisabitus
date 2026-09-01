import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/widgets/empty_state.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(width: 600, child: child)),
      ),
    );
  }

  const state = EmptyState(
    icon: Icons.local_fire_department_outlined,
    title: 'Sin rachas',
    hint: 'Empezá una',
  );

  testWidgets('centres itself in the space it is given', (tester) async {
    await pump(tester, const Center(child: state));

    final box = tester.getRect(find.byType(EmptyState));
    expect(box.center.dx, 300);
  });

  testWidgets('centres itself even where the parent aligns to the start', (
    tester,
  ) async {
    // The bug this guards: sized to its own content, the placeholder sat
    // hard against the left edge of every section that lays its children
    // out from the start — which is most of them.
    await pump(
      tester,
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [state],
      ),
    );

    final box = tester.getRect(find.byType(EmptyState));
    expect(
      box.center.dx,
      300,
      reason: 'the placeholder should sit in the middle of its section',
    );
    expect(
      tester.getCenter(find.text('Sin rachas')).dx,
      300,
      reason: 'and so should the text inside it',
    );
  });

  testWidgets('keeps its own children centred on each other', (tester) async {
    await pump(tester, const Center(child: state));

    expect(
      tester.getCenter(find.text('Empezá una')).dx,
      tester.getCenter(find.text('Sin rachas')).dx,
    );
  });
}
