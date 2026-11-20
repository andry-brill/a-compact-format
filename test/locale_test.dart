import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as en;
import 'package:any_compact_format/locales/fr.dart' as fr;
import 'package:any_compact_format/locales/hi.dart' as hi;
import 'package:any_compact_format/locales/it.dart' as it;
import 'package:any_compact_format/locales/pl.dart' as pl;
import 'package:any_compact_format/locales/ru.dart' as ru;
import 'package:any_compact_format/locales/uk.dart' as uk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Reference data: unicode-org/cldr-json commit
  // 7d2b9cb11cec08f4d333ad73209deb3df0711c3b, cldr-units-full/main/{uk,hi}/units.json.
  test('Ukrainian rare prefixes use the localized CLDR symbols', () {
    final options = CompactFormatOptions(locale: uk.locale, format: narrowCompact);
    expect(compactFormat(1e-30, options: options), '1кв');
    expect(compactFormat(1e-21, options: options), '1зп');
    expect(compactFormat(BigInt.from(10).pow(30), options: options), '1Кв');
    expect(compactFormat(BigInt.from(10).pow(30), options: options.copyWith(format: fileSizeDecimal)), '1 КвБ');
  });

  test('Hindi measurements use localized labels for singular and plural amounts', () {
    for (final (input, format, label) in [
      (0.0001, areaMetric, 'व॰ सें॰'),
      (1, areaMetric, 'वर्ग मी॰'),
      (1e6, areaMetric, 'वर्ग कि॰मी॰'),
      (0.000001, volumeMetric, 'घन सें॰ मी॰'),
      (1, volumeMetric, 'घन मी॰'),
      (1e9, volumeMetric, 'घन कि॰मी॰'),
      (0.001, volumeLitres, 'मि॰ ली॰'),
      (1e6, massMetric, 'ट'),
    ]) {
      final options = CompactFormatOptions(locale: hi.locale, format: format);
      expect(compactFormat(input, options: options), '1 $label');
      expect(compactFormat(input * 2, options: options), '2 $label');
    }
  });

  test('standard and narrow locale labels format all four magnitudes', () {
    const values = [1500, 1500000, 1.5e9, 1.5e12];
    for (final (standard, narrow, usual, short) in [
      (ru.locale, ru.narrow(), ['тыс.', 'млн', 'млрд', 'трлн'], ['т', 'М', 'Мд', 'Т']),
      (uk.locale, uk.narrow(), ['тис.', 'млн', 'млрд', 'трлн'], ['т', 'М', 'Мд', 'Т']),
      (pl.locale, pl.narrow(), ['tys.', 'mln', 'mld', 'bln'], ['t', 'M', 'Md', 'B']),
      (it.locale, it.narrow(), ['K', 'Mln', 'Mld', 'Bln'], ['K', 'M', 'Md', 'B']),
      (fr.locale, fr.narrow(), ['k', 'M', 'Md', 'Bn'], ['k', 'M', 'Md', 'B']),
    ]) {
      for (var i = 0; i < values.length; i++) {
        expect(
          compactFormat(
            values[i],
            options: CompactFormatOptions(locale: standard, format: narrowCompact),
          ),
          '1,5${usual[i]}',
        );
        expect(
          compactFormat(
            values[i],
            options: CompactFormatOptions(locale: narrow, format: narrowCompact),
          ),
          '1,5${short[i]}',
        );
      }
    }
    expect(en.narrow(), en.locale);
    expect(
      compactFormat(
        1536,
        options: CompactFormatOptions(locale: ru.locale, format: fileSizeBinary),
      ),
      '1,5 КиБ',
    );
    final custom = pl.narrow(k: '', M: 'x', B: 'G', T: 'y');
    expect(custom, pl.locale.copyWith(labels: {CompactLabel.thousand: '', CompactLabel.million: 'x', CompactLabel.billion: 'G', CompactLabel.trillion: 'y'}));
    expect(
      compactFormat(
        1.5e9,
        options: CompactFormatOptions(locale: custom, format: narrowCompact),
      ),
      '1,5G',
    );
    expect(
      compactFormat(
        1500000,
        options: CompactFormatOptions(locale: fr.narrow(), format: fileSizeDecimal),
      ),
      '1,5 Mo',
    );
  });

  test('quick start needs no settings and defaults to English across formats', () {
    expect(compactFormat(1234567), '1.23M');
    expect(compactFormat(1200), '1.2K');
    expect(compactFormat(1500, options: CompactFormatOptions(format: fileSizeDecimal)), '1.5 kB');
    expect(compactFormat(1500, options: CompactFormatOptions(format: lengthMetric)), '1.5 km');
    expect(
      compactFormat(
        1500,
        options: CompactFormatOptions(locale: uk.locale, format: lengthMetric),
      ),
      '1,5 км',
    );
  });

  test('copyWith overrides selected labels and preserves the selected locale', () {
    final custom = uk.locale.copyWith(labels: {CompactLabel.kilobyte: 'custom', CompactLabel.byte: ''});
    expect(custom.locale, const Locale('uk'));
    expect(custom.resolve(CompactLabel.megabyte), 'МБ');
    expect(uk.locale.resolve(CompactLabel.kilobyte), 'кБ');
    final options = CompactFormatOptions(locale: custom, format: fileSizeDecimal);
    expect(compactFormat(1500, options: options), '1,5 custom');
    expect(compactFormat(1e6, options: options), '1 МБ');
    expect(compactFormat(0, options: options), '0');
    expect(compactFormat(1500, options: options.copyWith(locale: en.locale)), '1.5 kB');
    expect(
      compactFormat(
        1500,
        options: options.copyWith(locale: custom.copyWith(locale: const Locale('en'))),
      ),
      '1.5 custom',
    );
    final localized = options.copyWith(format: localizedCompact);
    expect(compactFormat(1500, options: localized), compactFormat(1500, options: localized.copyWith(locale: uk.locale)));
  });

  test('locale snapshots and equality are immutable and independent of map order', () {
    final values = {CompactLabel.byte: 'Б', CompactLabel.kilobyte: 'кБ'};
    final first = CompactLocale(locale: const Locale('uk'), labels: values);
    values.clear();
    final equal = CompactLocale(locale: const Locale('uk'), labels: {CompactLabel.kilobyte: 'кБ', CompactLabel.byte: 'Б'});
    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first.copyWith(), first);
    expect(first.copyWith().hashCode, first.hashCode);
    expect(() => first.labels.clear(), throwsUnsupportedError);
    expect(first.copyWith(locale: const Locale('en')), isNot(first));
    expect(first.copyWith(labels: {CompactLabel.byte: 'B'}), isNot(first));
    expect(const CompactLabel('data.byte'), CompactLabel.byte);
    expect(CompactLabel.byte, isNot(CompactLabel.billion));
  });

  test('missing keys use only literal interval fallback, not English or parent locales', () {
    final empty = CompactLocale(locale: const Locale('uk', 'UA'), labels: {});
    final options = CompactFormatOptions(locale: empty, format: fileSizeDecimal);
    expect(compactFormat(1500, options: options), '1,5');
    expect(empty.resolve(CompactLabel.kilobyte, fallback: 'fallback'), 'fallback');
    final literal = CompactFormatDefinition(
      overrides: const [CompactInterval(suffixLabel: CompactLabel.kilobyte, suffix: 'literal', separator: ' ')],
    );
    expect(compactFormat(2, options: options.copyWith(format: literal)), '2 literal');
    expect(
      compactFormat(
        2,
        options: options.copyWith(
          format: literal,
          locale: empty.copyWith(labels: {CompactLabel.kilobyte: ''}),
        ),
      ),
      '2',
    );
    const customKey = CompactLabel('inventory.crate');
    final unknownNumeric = CompactLocale(locale: const Locale('zz', 'ZZ'), labels: {customKey: 'crate'});
    final customFormat = CompactFormatDefinition(
      overrides: const [CompactInterval(suffixLabel: customKey, separator: ' ')],
    );
    expect(
      compactFormat(
        1.5,
        options: CompactFormatOptions(locale: unknownNumeric, format: customFormat),
      ),
      '1.5 crate',
    );
  });

  test('options replace locales atomically; copyWith can clear the configuration', () {
    final parent = CompactFormatOptions(locale: uk.locale, format: fileSizeDecimal, explicitSign: true);
    final child = CompactLocale(locale: const Locale('en'), labels: {CompactLabel.kilobyte: 'KB'});
    final merged = parent.merge(CompactFormatOptions(locale: child));
    expect(merged.locale, same(child));
    expect(merged.format, same(parent.format));
    expect(compactFormat(1500, options: merged), '+1.5 KB');
    expect(compactFormat(1e6, options: merged), '+1');
    expect(parent.merge(const CompactFormatOptions()).locale, same(uk.locale));
    expect(parent.copyWith(locale: null).locale, isNull);
    expect(compactFormat(1, options: parent.copyWith(locale: null)), '+1 B');
    expect(compactFormat(1), '1');
  });

  test('label keys survive splits and callbacks see labels after rounding promotion', () {
    const prefix = CompactLabel('custom.prefix');
    const suffix = CompactLabel('custom.suffix');
    final locale = en.locale.copyWith(labels: {prefix: 'about', suffix: 'units'});
    final format = CompactFormatDefinition(
      overrides: const [CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 9), scale: CompactPower(power: 3), prefixLabel: prefix, suffixLabel: suffix, separator: '\u00a0')],
    );
    final split = format.copyWith(
      overrides: [const CompactInterval(from: CompactPower(power: 4), to: CompactPower(power: 5))],
    );
    final options = CompactFormatOptions(locale: locale, format: split);
    expect(compactFormat(1200, options: options), 'about\u00a01.2\u00a0units');
    expect(compactFormat(120000, options: options), 'about\u00a0120\u00a0units');
    expect(
      compactFormat(
        999950,
        options: options.copyWith(locale: uk.locale, format: fileSizeDecimal),
      ),
      '1 МБ',
    );
    final callback = CompactFormatDefinition(
      overrides: [CompactInterval(suffixLabel: suffix, separator: ' ', formatter: (context) => '${context.defaultText}!')],
    );
    expect(compactFormat(2, options: options.copyWith(format: callback)), '2 units!');
  });

  testWidgets('providers default to English and replace whole locales without merging labels', (tester) async {
    CompactLocale? selected;
    late StateSetter update;
    final sparse = CompactLocale(locale: const Locale('uk'), labels: {CompactLabel.kilobyte: 'local'});
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CompactFormatProvider(
          options: CompactFormatOptions(format: fileSizeDecimal),
          child: StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return CompactFormatProvider(
                options: CompactFormatOptions(locale: selected),
                child: Column(
                  children: [
                    const CompactFormatText(1500),
                    const CompactFormatText(1e6),
                    Builder(builder: (context) => Text(context.compactFormat(1500))),
                    CompactFormatText(
                      1500,
                      options: CompactFormatOptions(locale: uk.locale.copyWith(labels: {CompactLabel.kilobyte: 'text'})),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('1.5 kB'), findsNWidgets(2));
    expect(find.text('1 MB'), findsOneWidget);
    expect(find.text('1,5 text'), findsOneWidget);
    update(() => selected = sparse);
    await tester.pump();
    expect(find.text('1,5 local'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('1 MB'), findsNothing);
    expect(find.text('1,5 text'), findsOneWidget);
    update(() => selected = uk.locale);
    await tester.pump();
    expect(find.text('1,5 кБ'), findsNWidgets(2));
    expect(find.text('1 МБ'), findsOneWidget);
    update(() => selected = null);
    await tester.pump();
    expect(find.text('1.5 kB'), findsNWidgets(2));
  });
}
