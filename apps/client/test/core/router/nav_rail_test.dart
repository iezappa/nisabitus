import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/router/nav_rail.dart';
import 'package:nisabitus/core/theme/app_theme.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';

void main() {
  const destinations = [
    (Icons.checklist_outlined, Icons.checklist, 'Habits'),
    (Icons.favorite_border, Icons.favorite, 'Health'),
    (Icons.book_outlined, Icons.book, 'Journal'),
  ];

  testWidgets('renders an icons-only floating rail with accessible labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AccentColor.forest),
        home: Scaffold(
          body: NavRail(
            destinations: destinations,
            selectedIndex: 1,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(NavRail), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Habits'), findsNothing);
    expect(find.byTooltip('Habits'), findsOneWidget);
    expect(find.bySemanticsLabel('Health'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
  });

  testWidgets('selects destinations by index', (tester) async {
    final selected = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AccentColor.forest),
        home: Scaffold(
          body: NavRail(
            destinations: destinations,
            selectedIndex: 0,
            onSelected: selected.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Journal'));

    expect(selected, [2]);
  });
}
