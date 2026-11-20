import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/ja.dart' as ja;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback runs once after the entire base chain and preserves exact input', () {
    final seen = <Object>[];
    final options = CompactFormatOptions(
      locale: ja.locale,
      format: CompactFormatDefinition(base: CompactFormatDefinition(overrides: ja.narrowOverrides)),
      fallbackFormatter: (context) {
        seen.add(context.input);
        return context.input.toString();
      },
    );
    expect(compactFormat(15000, options: options), '1.5万');
    expect(seen, isEmpty);
    final tiny = Decimal.parse('0.000000000000000000000000000000000001');
    expect(compactFormat(tiny, options: options), tiny.toString());
    expect(seen, [tiny]);
    expect(compactFormat(0, options: options), '0');
    expect(seen, [tiny, 0]);
    final huge = BigInt.from(10).pow(50);
    expect(compactFormat(huge, options: options.copyWith(format: CompactFormatDefinition())), huge.toString());
  });

  test('fallback helpers, null and empty results have defined behavior', () {
    expect(CompactFormatOptions.defaults.fallbackFormatter, same(defaultFallbackFormatter));
    const reset = CompactFormatOptions(fallbackFormatter: defaultFallbackFormatter);
    expect(reset.fallbackFormatter, same(defaultFallbackFormatter));
    var options = CompactFormatOptions(format: CompactFormatDefinition(), fallbackFormatter: (context) => context.formatDecimal(context.input));
    expect(compactFormat(1234.56789, options: options), '1234.568');
    expect(compactFormat(1e-36, options: options.copyWith(fallbackFormatter: (_) => null)), '0');
    expect(compactFormat(1, options: options.copyWith(fallbackFormatter: (_) => '')), '');
    options = options.copyWith(fallbackFormatter: (CompactFormattingContext context) => context.input.toString());
    expect(options.copyWith(), options);
    expect(options.copyWith().hashCode, options.hashCode);
    expect(options.copyWith(fallbackFormatter: null).fallbackFormatter, same(defaultFallbackFormatter));
    expect(options.merge(const CompactFormatOptions()).fallbackFormatter, same(options.fallbackFormatter));
    expect(compactFormat(1e-36, options: options.copyWith(fallbackFormatter: null)), '0');
  });

  test('default getter preserves absent versus explicit overrides during composition', () {
    const absent = CompactFormatOptions();
    const explicit = CompactFormatOptions(fallbackFormatter: defaultFallbackFormatter);
    final parent = CompactFormatOptions(fallbackFormatter: (_) => 'parent');
    expect(absent.fallbackFormatter, same(defaultFallbackFormatter));
    expect(absent, isNot(explicit));
    expect(absent.copyWith(), absent);
    expect(absent.copyWith().hashCode, absent.hashCode);
    expect(parent.merge(absent.copyWith()).fallbackFormatter, same(parent.fallbackFormatter));
    expect(parent.merge(explicit).fallbackFormatter, same(defaultFallbackFormatter));
    expect(parent.merge(explicit.copyWith(fallbackFormatter: null)).fallbackFormatter, same(parent.fallbackFormatter));
    expect(explicit.copyWith(fallbackFormatter: null), absent);
  });

  test('selected format handlers and special numbers take precedence', () {
    String fallback(CompactFormattingContext context) => 'fallback';
    final options = CompactFormatOptions(fallbackFormatter: fallback);
    expect(compactFormat(1500, options: options), '1.5K');
    expect(compactFormat(0, options: options), 'fallback');
    expect(compactFormat(0, options: options.copyWith(format: fileSizeBinary)), '0 B');
    expect(compactFormat(double.infinity, options: options), '∞');
    expect(
      compactFormat(
        1,
        options: options.copyWith(format: CompactFormatDefinition(formatter: (_) => 'handled')),
      ),
      'handled',
    );
    expect(compactFormat(1, options: options.copyWith(format: scientificCompact)), '1 × 10⁰');
  });

  testWidgets('provider inherits fallback and rebuilds when only the callback changes', (tester) async {
    String first(CompactFormattingContext context) => 'first';
    String second(CompactFormattingContext context) => 'second';
    String local(CompactFormattingContext context) => 'local';
    final format = CompactFormatDefinition();
    Future<void> render(CompactFormatter callback) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CompactFormatProvider(
          options: CompactFormatOptions(format: format, fallbackFormatter: callback),
          child: CompactFormatProvider(
            child: Column(
              children: [
                const CompactFormatText(1),
                Builder(builder: (context) => Text(context.compactFormat(2))),
                CompactFormatText(3, options: CompactFormatOptions(fallbackFormatter: local)),
                const CompactFormatText(4, options: CompactFormatOptions(fallbackFormatter: defaultFallbackFormatter)),
              ],
            ),
          ),
        ),
      ),
    );
    await render(first);
    expect(find.text('first'), findsNWidgets(2));
    expect(find.text('local'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await render(second);
    expect(find.text('second'), findsNWidgets(2));
    expect(find.text('4'), findsOneWidget);
    expect(find.text('local'), findsOneWidget);
  });
}
