import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/theme/accent_backdrop.dart';
import 'package:nisabitus/core/theme/app_theme.dart';
import 'package:nisabitus/features/settings/domain/accent_color.dart';

void main() {
  testWidgets('paints one accent gradient behind its child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AccentColor.forest),
        home: const AccentBackdrop(child: SizedBox.expand()),
      ),
    );

    final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));

    expect(
      boxes.any(
        (box) =>
            box.decoration is BoxDecoration &&
            (box.decoration as BoxDecoration).gradient is LinearGradient,
      ),
      isTrue,
    );
    expect(
      boxes.any(
        (box) =>
            box.decoration is BoxDecoration &&
            (box.decoration as BoxDecoration).gradient is RadialGradient,
      ),
      isTrue,
    );
  });

  test('keeps the tinted page at the page brightness', () {
    const page = Color(0xFFFBFBFC);
    const accent = Color(0xFF0B6B4F);

    final tinted = HSLColor.fromColor(tintedPage(page, accent, dark: false))
        .lightness;
    final original = HSLColor.fromColor(page).lightness;

    expect(tinted, closeTo(original - 0.045, 0.001));
  });
}
