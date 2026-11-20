import 'package:any_compact_format_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opening showcase reads left to right across six rows in a square grid', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CompactExampleApp());
    final showcase = find.byKey(const ValueKey('feature-showcase'));
    final tableFinder = find.descendant(of: showcase, matching: find.byType(Table));
    final tables = tester.widgetList<Table>(tableFinder).toList();
    expect(tables, hasLength(2));
    for (final table in tables) {
      expect(table.children, hasLength(7));
      expect(table.children.every((row) => row.children.length == 3), isTrue);
    }
    expect(tester.getTopLeft(tableFinder.last).dx - tester.getTopRight(tableFinder.first).dx, 16);
    expect(tester.getTopLeft(tableFinder.first).dy, tester.getTopLeft(tableFinder.last).dy);
    final header = tester.widget<Text>(find.descendant(of: showcase, matching: find.text('Input')).first);
    final input = tester.widget<Text>(find.descendant(of: showcase, matching: find.text('1 234')));
    expect(header.style, input.style);
    const features = ['Compact numbers', 'Tiny decimals', 'Huge integers', 'Scientific', 'Engineering', 'SI prefixes', 'Sign & precision', 'Localization', 'File sizes', 'Area', 'Mass', 'Precision & rounding'];
    for (var index = 0; index < features.length; index++) {
      final featureCell = tables[index % 2].children[index ~/ 2 + 1].children[0];
      expect(find.descendant(of: find.byWidget(featureCell), matching: find.text(features[index])), findsOneWidget);
    }
    final size = tester.getSize(showcase);
    expect(size.width, size.height);
    expect(find.descendant(of: showcase, matching: find.text('Українська')), findsNothing);
    expect(find.descendant(of: showcase, matching: find.text('123 000 000 000 000 000')), findsOneWidget);
    expect(find.descendant(of: showcase, matching: find.text('0.000000000001234')), findsNWidgets(2));
    for (final result in ['1.23M', '0.0₁₁123', '1230¹⁵0', '1.23 × 10⁻¹²', '12.3 × 10⁶', '1.23µ', '+1.20k', '1,23тис.', '1.5 KiB', '1.5 km²', '2.5 µg', '-1.2k']) {
      expect(
        find.descendant(of: showcase, matching: find.text(result)),
        findsWidgets,
        reason: result,
      );
    }
    expect(tester.getBottomRight(showcase).dy, lessThan(tester.getTopLeft(find.byKey(const ValueKey('en-localized'))).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('showcase stacks without horizontal scrolling at narrow widths and larger text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const CompactExampleApp());
    final showcase = find.byKey(const ValueKey('feature-showcase'));
    expect(find.descendant(of: showcase, matching: find.byType(Table)), findsNothing);
    expect(find.descendant(of: showcase, matching: find.byType(Scrollable)), findsNothing);
    final last = find.byKey(const ValueKey('showcase-Precision & rounding'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: last, matching: find.text('-1.2k')), findsOneWidget);
    expect(tester.getTopLeft(last).dx, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(last).dx, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });
}
