import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as en;
import 'package:any_compact_format/locales/uk.dart' as uk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final presets = <(CompactFormatDefinition, String, String, List<(int, String, String)>)>[
    (lengthMetric, 'm', 'м', [(-6, 'µm', 'мкм'), (-3, 'mm', 'мм'), (-2, 'cm', 'см'), (0, 'm', 'м'), (3, 'km', 'км')]),
    (areaMetric, 'm²', 'м²', [(-6, 'mm²', 'мм²'), (-4, 'cm²', 'см²'), (0, 'm²', 'м²'), (6, 'km²', 'км²')]),
    (volumeMetric, 'm³', 'м³', [(-9, 'mm³', 'мм³'), (-6, 'cm³', 'см³'), (0, 'm³', 'м³'), (9, 'km³', 'км³')]),
    (volumeLitres, 'L', 'л', [(-6, 'µL', 'мкл'), (-3, 'mL', 'мл'), (-2, 'cL', 'сл'), (-1, 'dL', 'дл'), (0, 'L', 'л'), (2, 'hL', 'гл'), (3, 'kL', 'кл')]),
    (massMetric, 'g', 'г', [(-6, 'µg', 'мкг'), (-3, 'mg', 'мг'), (0, 'g', 'г'), (3, 'kg', 'кг'), (6, 't', 'т')]),
  ];

  test('all metric thresholds use correct powers and default English labels', () {
    for (final (format, _, _, units) in presets) {
      final options = CompactFormatOptions(locale: en.locale, format: format);
      for (final (power, symbol, _) in units) {
        final value = Decimal.parse('1e$power');
        expect(compactFormat(value, options: options), '1 $symbol');
        expect(compactFormat(-value, options: options), '-1 $symbol');
      }
      expect(compactFormat(BigInt.from(10).pow(units.last.$1 + 3), options: options), '1000 ${units.last.$2}');
      expect(compactFormat(Decimal.parse('1e${units.first.$1 - 3}'), options: options), '0.001 ${units.first.$2}');
    }
    final area = CompactFormatOptions(locale: en.locale, format: areaMetric);
    expect(compactFormat(10000, options: area), '10000 m²');
    expect(compactFormat(Decimal.parse('0.0001'), options: area), '1 cm²');
    expect(compactFormat(1000000, options: area), '1 km²');
    expect(compactFormat(Decimal.parse('0.000001'), options: area.copyWith(format: volumeMetric)), '1 cm³');
  });

  test('rounding promotes into every metric unit without double scaling', () {
    for (final (format, _, _, units) in presets) {
      final options = CompactFormatOptions(locale: en.locale, format: format);
      for (var index = 1; index < units.length; index++) {
        final (power, symbol, _) = units[index];
        final almost = Decimal.parse('9.999999e${power - 1}');
        expect(compactFormat(almost, options: options), '1 $symbol');
        expect(compactFormat(-almost, options: options), '-1 $symbol');
        final truncated = options.copyWith(precision: const CompactPrecision.significant(maximum: 3), rounding: CompactRounding.towardZero);
        expect(compactFormat(almost, options: truncated), endsWith(' ${units[index - 1].$2}'));
      }
    }
  });

  test('zero retains base units, localized labels, padding and explicit signs', () {
    for (final (format, english, ukrainian, _) in presets) {
      final options = CompactFormatOptions(locale: en.locale, format: format);
      expect(compactFormat(BigInt.zero, options: options), '0 $english');
      expect(compactFormat(-0.0, options: options), '0 $english');
      expect(
        compactFormat(
          0,
          options: options.copyWith(locale: uk.locale.copyWith(locale: const Locale('uk', 'UA'))),
        ),
        '0 $ukrainian',
      );
      expect(compactFormat(0, options: options.copyWith(explicitSign: true, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))), '+0.00 $english');
      expect(
        compactFormat(
          0,
          options: options.copyWith(
            format: format.copyWith(
              overrides: [const CompactInterval(from: CompactPower(power: 20), to: CompactPower(power: 21))],
            ),
          ),
        ),
        '0 $english',
      );
    }
  });

  test('exact input types, fraction rounding and extreme values share the decimal engine', () {
    final options = CompactFormatOptions(locale: en.locale, format: massMetric);
    for (final value in [1500, Decimal.parse('1500'), BigInt.from(1500)]) {
      expect(compactFormat(value, options: options), '1.5 kg');
    }
    expect(
      compactFormat(
        1250,
        options: options.copyWith(precision: const CompactPrecision.fraction(maximum: 1), rounding: CompactRounding.halfEven),
      ),
      '1.2 kg',
    );
    expect(compactFormat(1250, options: options.copyWith(precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))), '1.25 kg');
    expect(compactFormat(BigInt.from(10).pow(400), options: options), '1${'0' * 394} t');
    expect(compactFormat(Decimal.parse('1e-400'), options: options), '0.${'0' * 393}1 µg');
  });

  test('Ukrainian is explicit and covers every default label without a registry', () {
    expect(CompactFormatOptions.defaults.locale, same(en.locale));
    expect(uk.locale.labels.keys.toSet(), en.locale.labels.keys.toSet());
    final options = CompactFormatOptions(
      locale: en.locale.copyWith(locale: const Locale('uk', 'UA')),
      format: lengthMetric,
    );
    // Importing the catalog alone does not enable it.
    expect(compactFormat(1500, options: options), '1,5 km');
    expect(compactFormat(1500, options: options.copyWith(locale: uk.locale)), '1,5 км');
    expect(compactFormat(1500, options: options.copyWith(locale: en.locale)), '1.5 km');
    for (final (format, _, _, units) in presets) {
      for (final (power, _, symbol) in units) {
        expect(
          compactFormat(
            Decimal.parse('1.5e$power'),
            options: options.copyWith(format: format, locale: uk.locale),
          ),
          '1,5 $symbol',
        );
      }
    }
    expect(
      compactFormat(
        1e6,
        options: options.copyWith(format: narrowNatural, locale: uk.locale),
      ),
      '1млн',
    );
    expect(
      compactFormat(
        1536,
        options: options.copyWith(format: fileSizeBinary, locale: uk.locale),
      ),
      '1,5 КіБ',
    );
    expect(
      compactFormat(
        1500,
        options: options.copyWith(format: fileSizeDecimal, locale: uk.locale),
      ),
      '1,5 кБ',
    );
  });

  test('custom labels override bundled catalogs and survive interval splitting', () {
    final catalog = uk.locale.copyWith(labels: {CompactLabel.kilometre: 'custom', CompactLabel.metre: ''});
    final format = lengthMetric.copyWith(
      overrides: [const CompactInterval(from: CompactPower(power: 4), to: CompactPower(power: 5))],
    );
    final options = CompactFormatOptions(locale: catalog, format: format);
    expect(compactFormat(1500, options: options), '1,5 custom');
    expect(compactFormat(150000, options: options), '150 custom');
    expect(compactFormat(0, options: options), '0');
    expect(compactFormat(2, options: options), '2');
    expect(compactFormat(Decimal.parse('0.01'), options: options), '1 см');
  });

  testWidgets('provider can switch between default English and imported Ukrainian', (tester) async {
    CompactLocale? locale;
    late StateSetter update;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return CompactFormatProvider(
              options: CompactFormatOptions(locale: locale, format: areaMetric),
              child: const Column(children: [CompactFormatText(1500000), CompactFormatText(0)]),
            );
          },
        ),
      ),
    );
    expect(find.text('1.5 km²'), findsOneWidget);
    update(() => locale = uk.locale);
    await tester.pump();
    expect(find.text('1,5 км²'), findsOneWidget);
    expect(find.text('0 м²'), findsOneWidget);
    update(() => locale = null);
    await tester.pump();
    expect(find.text('1.5 km²'), findsOneWidget);
    expect(find.text('0 m²'), findsOneWidget);
  });
}
