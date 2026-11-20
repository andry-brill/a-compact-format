import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cells = ['en-localized', 'en-narrow'];
  Finder pageScroll() => find.descendant(of: find.byKey(const ValueKey('page-scroll')), matching: find.byType(Scrollable)).first;
  Finder cell(String id) => find.byKey(ValueKey(id));
  Finder sample(String cellId, String sampleId) => find.descendant(of: cell(cellId), matching: find.byKey(ValueKey(sampleId)));
  Future<void> verify(WidgetTester tester, String sampleId, List<String> expected) async {
    for (var i = 0; i < cells.length; i++) {
      final target = sample(cells[i], sampleId);
      await tester.ensureVisible(target);
      expect(
        find.descendant(of: target, matching: find.text(expected[i])),
        findsOneWidget,
        reason: '${cells[i]} / $sampleId',
      );
    }
  }

  testWidgets('one row compares the same examples in two format columns', (tester) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CompactExampleApp());
    expect(find.byType(Scrollable), findsNWidgets(3));
    expect(find.byType(ListView), findsNothing);
    for (final id in cells) {
      expect(find.descendant(of: cell(id), matching: find.byType(Scrollable)), findsNothing);
      expect(tester.getBottomRight(sample(id, 'null-custom')).dy, lessThanOrEqualTo(tester.getBottomRight(cell(id)).dy));
    }
    expect(tester.getSize(cell('en-localized')).height, tester.getSize(cell('en-narrow')).height);
    final topTables = find.descendant(of: find.byKey(const ValueKey('feature-showcase')), matching: find.byType(Table));
    expect(tester.getSize(cell('en-localized')).width, tester.getSize(topTables.first).width);
    expect(tester.getSize(cell('en-narrow')).width, tester.getSize(topTables.last).width);
    expect(tester.getTopLeft(cell('en-localized')).dx, tester.getTopLeft(topTables.first).dx);
    expect(tester.getTopRight(cell('en-narrow')).dx, tester.getTopRight(topTables.last).dx);
    final selector = find.byKey(const ValueKey('comparison-locale'));
    expect(tester.getTopLeft(selector).dx, tester.getTopLeft(topTables.first).dx);
    expect(tester.getTopRight(selector).dx, tester.getTopRight(topTables.last).dx);
    expect(find.byType(TextField), findsNothing);
    expect(tester.getTopLeft(cell('en-localized')).dy, tester.getTopLeft(cell('en-narrow')).dy);

    expect(tester.getTopLeft(cell('en-localized')).dx, lessThan(tester.getTopLeft(cell('en-narrow')).dx));

    await verify(tester, 'default', ['1.23M', '1.23M']);
    await verify(tester, 'billions', ['1B', '1B']);
    await verify(tester, 'milli', ['0.001', '1m']);
    await verify(tester, 'micro', ['0.000001', '1µ']);
    await verify(tester, 'two-digits', ['1.2M', '1.2M']);
    await verify(tester, 'three-significant-digits', ['12.0K', '12.0k']);
    await verify(tester, 'two-decimal-places', ['12.50K', '12.50k']);
    for (final id in cells) {
      final text = tester.widget<CompactFormatText>(find.descendant(of: sample(id, 'two-decimal-places'), matching: find.byType(CompactFormatText)));
      expect(text.value, 12500);
      expect(text.options!.precision, const CompactPrecision.fraction(minimum: 2, maximum: 2));
    }
    await verify(tester, 'boundary', ['1M', '1M']);
    await verify(tester, 'negative', ['-1.23M', '-1.23M']);
    await verify(tester, 'sign', ['+1.2K', '+1.2k']);
    await verify(tester, 'below-override', ['1.2K', '1.2k']);
    await verify(tester, 'interval-callback', List.filled(2, '1 million exactly'));
    await verify(tester, 'null-interval', ['1.23 million', '1.23 million']);
    await verify(tester, 'millions-boundary', ['1B', '1B']);
    await verify(tester, 'above-override', ['1B', '1B']);
    await verify(tester, 'symbol', List.filled(2, '1bn'));
    await verify(tester, 'regional', ['1.23 L', '1.23 L']);
    await verify(tester, 'unscaled', ['0.000001', '0.000001']);
    await verify(tester, 'nested', ['1.2M', '1.2M']);
    await verify(tester, 'builder', ['1.2K', '1.2k']);
    await verify(tester, 'custom', List.filled(2, 'Value 42'));
    await verify(tester, 'null-custom', ['1.2K', '1.2k']);
    expect(find.byType(Scrollable), findsNWidgets(3));
    expect(tester.state<ScrollableState>(pageScroll()).position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one page scrolls through fully expanded cells on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CompactExampleApp());
    await verify(tester, 'default', ['1.23M', '1.23M']);
    await verify(tester, 'null-custom', ['1.2K', '1.2k']);
    expect(find.byType(Scrollable), findsNWidgets(3));
    expect(tester.state<ScrollableState>(pageScroll()).position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('locale selector updates both formats with bundled labels', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CompactExampleApp());
    final selector = find.byKey(const ValueKey('comparison-locale'));
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(selector);
    expect(dropdown.initialValue, 'en');
    final button = tester.widget<DropdownButton<String>>(find.descendant(of: selector, matching: find.byType(DropdownButton<String>)));
    expect(button.items!.map((item) => item.value), containsAll(['bg', 'cs', 'de', 'en', 'es', 'fr', 'hi', 'hu', 'id', 'it', 'ja', 'ko', 'nl', 'pl', 'pt', 'pt_pt', 'ro', 'ru', 'sk', 'sv', 'tr', 'uk', 'vi', 'zh']));
    await tester.tap(selector);
    await tester.pumpAndSettle();
    final ukrainian = find.text('Ukrainian (uk)').last;
    await tester.scrollUntilVisible(find.text('Ukrainian (uk)'), 250, scrollable: find.byType(Scrollable).last);
    await tester.tap(ukrainian);
    await tester.pumpAndSettle();
    for (final (id, expected) in [('uk-localized', '1,23 млн'), ('uk-narrow', '1,23млн')]) {
      final target = sample(id, 'default');
      await tester.ensureVisible(target);
      expect(find.descendant(of: target, matching: find.text(expected)), findsOneWidget);
    }
    expect(cell('nb-localized'), findsNothing);
    expect(cell('nb-narrow'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notation comparison spans all exponents and applies rounding controls', (tester) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CompactExampleApp());
    final panel = find.byKey(const ValueKey('notation-comparison'));
    await tester.ensureVisible(panel);
    await tester.pumpAndSettle();
    expect(find.text('2130₆0'), findsOneWidget);
    expect(find.text('2130⁶0'), findsOneWidget);
    for (var exponent = -36; exponent <= 36; exponent++) {
      expect(find.byKey(ValueKey('notation-row-10^${exponent > 0 ? '+' : ''}$exponent')), findsOneWidget);
      expect(find.byKey(ValueKey('notation-row--10^${exponent > 0 ? '+' : ''}$exponent')), findsOneWidget);
    }
    final rounding = find.byKey(const ValueKey('notation-rounding'));
    await tester.ensureVisible(rounding);
    await tester.tap(rounding);
    await tester.pumpAndSettle();
    await tester.tap(find.text('halfEven').last);
    await tester.pumpAndSettle();
    final precision = find.byKey(const ValueKey('notation-precision'));
    await tester.tap(precision);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 fraction digit').last);
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('notation-row-1.25'));
    expect(find.descendant(of: row, matching: find.text('1.2')), findsNWidgets(6));
    expect(find.descendant(of: row, matching: find.text('1.2 × 10⁰')), findsNWidgets(2));
    await tester.tap(precision);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 significant').last);
    await tester.pumpAndSettle();
    final samples = find.byKey(const ValueKey('notation-samples'));
    for (final series in [
      ('Growing integers · 0…+36', '123 456 789 012 345 678 901', '1 234 567 890 123 456 789 012 345 678 901 234 567', '1230³⁴0'),
      ('Growing fractions · 1…36 digits', '0.12', '0.123456789012345678901234567890123456', '0.123'),
      ('Leading zeros · −1…−36', '0.00123456789', '0.${'0' * 35}123456789', '0.0₃₅123'),
    ]) {
      await tester.ensureVisible(samples);
      await tester.tap(samples);
      await tester.pumpAndSettle();
      await tester.tap(find.text(series.$1).last);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('notation-row-${series.$2}')), findsOneWidget);
      for (final sign in ['', '-']) {
        final last = find.byKey(ValueKey('notation-row-$sign${series.$3}'));
        expect(last, findsOneWidget);
        final input = find.descendant(of: last, matching: find.byType(Tooltip)).first;
        expect(Decimal.parse(tester.widget<Tooltip>(input).message!), Decimal.parse('$sign${series.$3.replaceAll(' ', '')}'));
        final natural = tester.widget<Row>(last).children[3];
        expect(find.descendant(of: find.byWidget(natural), matching: find.text('$sign${series.$4}')), findsOneWidget);
      }
    }
    await tester.ensureVisible(samples);
    await tester.tap(samples);
    await tester.pumpAndSettle();
    await tester.tap(find.text('File sizes · bytes').last);
    await tester.pumpAndSettle();
    await tester.tap(precision);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 fraction digits').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: panel, matching: find.text('fileSizeBinary')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('fileSizeDecimal')), findsOneWidget);
    for (final sample in [('1536', '1.5 KiB', '1.54 kB'), ('-1536', '-1.5 KiB', '-1.54 kB'), ('1048575', '1 MiB', '1.05 MB')]) {
      final row = find.byKey(ValueKey('notation-row-${sample.$1}'));
      expect(find.descendant(of: row, matching: find.text(sample.$2)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(sample.$3)), findsOneWidget);
    }
    expect(find.descendant(of: find.byKey(const ValueKey('notation-row-0')), matching: find.text('0 B')), findsNWidgets(2));
    final locale = find.byKey(const ValueKey('notation-locale'));
    await tester.ensureVisible(locale);
    await tester.tap(locale);
    await tester.pumpAndSettle();
    await tester.tap(find.text('uk_UA').last);
    await tester.pumpAndSettle();
    final translated = find.byKey(const ValueKey('notation-row-1536'));
    expect(find.descendant(of: translated, matching: find.text('1,5 КіБ')), findsOneWidget);
    expect(find.descendant(of: translated, matching: find.text('1,54 кБ')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('notation-row-0')), matching: find.text('0 Б')), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('metric sample sets render English and opt-in Ukrainian labels', (tester) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CompactExampleApp());
    final samples = find.byKey(const ValueKey('notation-samples'));
    final locale = find.byKey(const ValueKey('notation-locale'));
    Future<void> select(Finder control, String value) async {
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      final option = find.text(value).last;
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
    }

    for (final sample in [
      ('Length · metres', 'lengthMetric', '1.5 km', '1,5 км', '0 m', '0 м'),
      ('Area · square metres', 'areaMetric', '1500 m²', '1500 м²', '0 m²', '0 м²'),
      ('Volume · cubic metres', 'volumeMetric', '1500 m³', '1500 м³', '0 m³', '0 м³'),
      ('Liquid volume · litres', 'volumeLitres', '1.5 kL', '1,5 кл', '0 L', '0 л'),
      ('Mass · grams', 'massMetric', '1.5 kg', '1,5 кг', '0 g', '0 г'),
    ]) {
      await select(samples, sample.$1);
      await select(locale, 'en');
      expect(find.descendant(of: find.byKey(const ValueKey('notation-comparison')), matching: find.text(sample.$2)), findsOneWidget);
      final row = find.byKey(const ValueKey('notation-row-1500'));
      final zero = find.byKey(const ValueKey('notation-row-0'));
      expect(find.descendant(of: row, matching: find.text(sample.$3)), findsOneWidget);
      expect(find.descendant(of: zero, matching: find.text(sample.$5)), findsOneWidget);
      await select(locale, 'uk_UA');
      expect(find.descendant(of: row, matching: find.text(sample.$4)), findsOneWidget);
      expect(find.descendant(of: zero, matching: find.text(sample.$6)), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
