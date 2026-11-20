import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String render(Object value, {CompactFormatDefinition? format, CompactPrecision? precision, CompactRounding? rounding, CompactLocale? locale}) => compactFormat(
    value,
    options: CompactFormatOptions(locale: locale ?? english.locale, format: format ?? narrowNatural, precision: precision, rounding: rounding),
  );

  test('num, Decimal and BigInt use the same notation and rounding engine', () {
    for (final format in [localizedCompact, narrowCompact, narrowNatural, zeroSubscriptCompact, zeroSuperscriptCompact, scientificCompact, engineeringCompact]) {
      for (final literal in ['2130000000', '-1234567', '999500', '0', '1']) {
        final expected = render(Decimal.parse(literal), format: format);
        expect(render(BigInt.parse(literal), format: format), expected);
        expect(render(int.parse(literal), format: format), expected);
        expect(render(double.parse(literal), format: format), expected);
      }
    }
    expect(() => render('123'), throwsArgumentError);
  });

  test('exact inputs retain digits beyond binary precision and range', () {
    final integer = BigInt.parse('900719925474099312345678901234567890');
    final decimal = CompactFormatDefinition(notation: const CompactNotation.decimal());
    expect(render(integer, format: decimal, precision: const CompactPrecision.significant(maximum: 50)), integer.toString());
    expect(render(Decimal.parse('1.2345678901234567890123456789'), format: decimal, precision: const CompactPrecision.fraction(maximum: 28)), '1.2345678901234567890123456789');
    expect(render(BigInt.from(10).pow(400), format: scientificCompact), '1 × 10⁴⁰⁰');
    expect(render(Decimal.parse('1e-1000'), format: scientificCompact), '1 × 10⁻¹⁰⁰⁰');
    expect(render(Decimal.parse('1e-1000')), '0.0₉₉₉1');
    expect(render(BigInt.from(10).pow(1000)), '10¹⁰⁰⁰0');
    expect(render(BigInt.from(10).pow(400), format: localizedCompact), '1${'0' * 388}T');
    expect(render(1000, format: localizedCompact, precision: const CompactPrecision.fraction(minimum: 1000, maximum: 1000)), '1.${'0' * 1000}K');
    expect(render(Decimal.parse('1234.5678901234567890123456789'), format: localizedCompact, precision: const CompactPrecision.significant(maximum: 30)), '1.2345678901234567890123456789K');
    expect(
      compactFormat(
        double.infinity,
        options: CompactFormatOptions(locale: english.locale, format: scientificCompact, explicitSign: true),
      ),
      '+∞',
    );
    expect(render(double.negativeInfinity, format: scientificCompact), '-∞');
  });

  test('all rounding directions apply symmetrically to exact decimal ties', () {
    final expected = <CompactRounding, List<String>>{
      CompactRounding.halfAwayFromZero: ['1.3', '-1.3', '1.4', '-1.4'],
      CompactRounding.halfEven: ['1.2', '-1.2', '1.4', '-1.4'],
      CompactRounding.towardZero: ['1.2', '-1.2', '1.3', '-1.3'],
      CompactRounding.floor: ['1.2', '-1.3', '1.3', '-1.4'],
      CompactRounding.ceil: ['1.3', '-1.2', '1.4', '-1.3'],
    };
    for (final mode in expected.entries) {
      var index = 0;
      for (final value in ['1.25', '-1.25', '1.35', '-1.35']) {
        for (final precision in [const CompactPrecision.fraction(maximum: 1), const CompactPrecision.significant(maximum: 2)]) {
          expect(
            render(Decimal.parse(value), precision: precision, rounding: mode.key),
            mode.value[index],
            reason: '${mode.key}: $value',
          );
        }
        index++;
      }
    }
    expect(render(Decimal.parse('-0.001'), precision: const CompactPrecision.fraction(minimum: 2, maximum: 2)), '0.00');
    expect(render(Decimal.parse('1.24999999999999999999'), precision: const CompactPrecision.fraction(maximum: 1)), '1.2');
    expect(render(Decimal.parse('1.25000000000000000001'), precision: const CompactPrecision.fraction(maximum: 1), rounding: CompactRounding.halfEven), '1.3');
  });

  test('scientific and engineering normalize after carry using original input', () {
    for (final sample in <String, (String, String)>{
      '12345': ('1.23 × 10⁴', '12.3 × 10³'),
      '0.000012345': ('1.23 × 10⁻⁵', '12.3 × 10⁻⁶'),
      '-0.0012345': ('-1.23 × 10⁻³', '-1.23 × 10⁻³'),
      '999500': ('1 × 10⁶', '1 × 10⁶'),
      '0.0009995': ('1 × 10⁻³', '1 × 10⁻³'),
      '0': ('0', '0'),
    }.entries) {
      expect(render(Decimal.parse(sample.key), format: scientificCompact), sample.value.$1);
      expect(render(Decimal.parse(sample.key), format: engineeringCompact), sample.value.$2);
    }
    expect(render(Decimal.parse('999950'), format: scientificCompact, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2)), '1.00 × 10⁶');
    expect(render(Decimal.parse('999950'), format: engineeringCompact, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2)), '999.95 × 10³');
    expect(render(Decimal.parse('999500'), format: scientificCompact, rounding: CompactRounding.towardZero), '9.99 × 10⁵');
    expect(render(0, format: scientificCompact, precision: const CompactPrecision.significant(minimum: 3, maximum: 3)), '0.00');
  });

  test('zero counts surround runs and preserve precision padding', () {
    expect(render(213000000, format: zeroSubscriptCompact), '2130₆0');
    expect(render(213000000, format: zeroSuperscriptCompact), '2130⁶0');
    expect(render(-213000000, format: zeroSubscriptCompact), '-2130₆0');
    expect(render(-213000000, format: zeroSuperscriptCompact), '-2130⁶0');
    expect(render(2130000000, format: zeroSubscriptCompact), '2130₇0');
    expect(render(2130000000, format: zeroSuperscriptCompact), '2130⁷0');
    expect(render(Decimal.parse('1e-36'), format: zeroSuperscriptCompact), '0.0³⁵1');
    expect(render(Decimal.parse('1e-36'), format: zeroSubscriptCompact), '0.0₃₅1');
    expect(render(1000, format: zeroSubscriptCompact), '1000');
    expect(render(10000, format: zeroSubscriptCompact), '10₄0');
    expect(render(Decimal.parse('0.00009999'), format: zeroSubscriptCompact), '0.0001');
    expect(render(Decimal.parse('0.0000012'), format: zeroSubscriptCompact, precision: const CompactPrecision.significant(minimum: 4, maximum: 4)), '0.0₅1200');
    expect(render(Decimal.parse('1.2'), format: zeroSubscriptCompact, precision: const CompactPrecision.fraction(minimum: 6, maximum: 6)), '1.200000');
    expect(render(10000, format: zeroSubscriptCompact, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2)), '10000.00');
    for (var digit = 0; digit < 10; digit++) {
      final value = BigInt.from(10).pow(10 + digit);
      expect(render(value, format: zeroSubscriptCompact), '10₁${'₀₁₂₃₄₅₆₇₈₉'[digit]}0');
      expect(render(value, format: zeroSuperscriptCompact), '10¹${'⁰¹²³⁴⁵⁶⁷⁸⁹'[digit]}0');
    }
  });

  test('narrowNatural keeps k M B and promotes to counted zeros beyond B', () {
    for (final sample in <String, String>{
      '1e-36': '0.0₃₅1',
      '0.135487': '0.135',
      '0.9999': '1',
      '999.5': '1k',
      '1200': '1.2k',
      '1234567': '1.23M',
      '2130000000': '2.13B',
      '999499999999': '999B',
      '999500000000': '10¹²0',
      '1e12': '10¹²0',
      '2.13e36': '2130³⁴0',
    }.entries) {
      expect(render(Decimal.parse(sample.key)), sample.value, reason: sample.key);
      expect(render(-Decimal.parse(sample.key)), '-${sample.value}', reason: '-${sample.key}');
    }
    expect(render(Decimal.parse('999500000000'), rounding: CompactRounding.towardZero), '999B');
    expect(render(Decimal.parse('1e-36'), locale: english.locale.copyWith(locale: Locale('nb'))), '0,0₃₅1');
    expect(
      render(
        Decimal.parse('1.23e-36'),
        format: scientificCompact,
        locale: english.locale.copyWith(locale: Locale('nb')),
      ),
      '1,23 × 10⁻³⁶',
    );
  });

  test('rounding options inherit and can be cleared', () {
    const options = CompactFormatOptions(rounding: CompactRounding.halfEven);
    expect(options.merge(const CompactFormatOptions()).rounding, CompactRounding.halfEven);
    expect(options.merge(const CompactFormatOptions(rounding: CompactRounding.floor)).rounding, CompactRounding.floor);
    expect(options.copyWith(rounding: null), const CompactFormatOptions());
    expect(options.copyWith(), options);
    expect(options.copyWith().hashCode, options.hashCode);
  });

  testWidgets('Flutter entry points retain Decimal and BigInt and inherit rounding', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CompactFormatProvider(
          options: CompactFormatOptions(locale: english.locale, format: narrowNatural, precision: const CompactPrecision.significant(maximum: 2), rounding: CompactRounding.halfEven),
          child: Column(
            children: [
              CompactFormatText(Decimal.parse('1.25')),
              CompactFormatText(BigInt.from(10).pow(400)),
              Builder(
                builder: (context) => Text(context.compactFormat(Decimal.parse('-1.25'), options: const CompactFormatOptions(rounding: CompactRounding.floor))),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('1.2'), findsOneWidget);
    expect(find.text('10⁴⁰⁰0'), findsOneWidget);
    expect(find.text('-1.3'), findsOneWidget);
  });

  test('callbacks and interval merging preserve exact values and notation', () {
    final source = Decimal.parse('1.234567890123456789e400');
    final format = CompactFormatDefinition(
      overrides: [
        CompactInterval(
          from: CompactPower(power: 399),
          to: CompactPower(power: 402),
          scale: CompactPower(power: 400),
          formatter: (context) {
            expect(context.input, same(source));
            expect(context.decimalInput, source);
            expect(context.decimalValue, Decimal.parse('1.23'));
            return context.defaultText;
          },
          suffix: ' units',
        ),
      ],
    );
    expect(render(source, format: format), '1.23 units');
    final split =
        CompactFormatDefinition(
          notation: const CompactNotation.scientific(),
          overrides: const [CompactInterval(from: CompactPower(power: -1000), to: CompactPower(power: 1000), notation: CompactNotation.zeroCount())],
        ).copyWith(
          overrides: [const CompactInterval(from: CompactPower(power: 0), to: CompactPower(power: 3))],
        );
    expect(split.overrides.first.notation, const CompactNotation.zeroCount());
    expect(render(Decimal.parse('1e-1001'), format: split), '1 × 10⁻¹⁰⁰¹');
    expect(() => CompactFormatDefinition(notation: const CompactNotation.zeroCount(minimumZeros: 1)), throwsArgumentError);
    expect(
      () => CompactFormatDefinition(
        overrides: [const CompactInterval(scale: CompactPower(power: 3), notation: CompactNotation.scientific())],
      ),
      throwsArgumentError,
    );
  });
}
