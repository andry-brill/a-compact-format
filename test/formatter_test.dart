import 'dart:math' as math;
import 'dart:typed_data';

import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final en = CompactFormatOptions(locale: english.locale);
String render(num value, {CompactPrecision? precision, CompactLocale? locale, bool? sign}) => compactFormat(
  value,
  options: CompactFormatOptions(locale: locale ?? english.locale, format: narrowCompact, precision: precision, explicitSign: sign),
);

// Neighbours around positive doubles, without 64-bit integers (also runs on web).
double adjacent(double value, int direction) {
  final bytes = ByteData(8)..setFloat64(0, value);
  var low = bytes.getUint32(4);
  var high = bytes.getUint32(0);
  if (direction > 0) {
    if (low == 0xffffffff) {
      low = 0;
      high++;
    } else {
      low++;
    }
  } else {
    if (low == 0) {
      low = 0xffffffff;
      high--;
    } else {
      low--;
    }
  }
  bytes.setUint32(0, high);
  bytes.setUint32(4, low);
  return bytes.getFloat64(0);
}

void main() {
  const narrowSymbols = ['q', 'r', 'y', 'z', 'a', 'f', 'p', 'n', 'µ', 'm', '', 'k', 'M', 'B', 'T', 'P', 'E', 'Z', 'Y', 'R', 'Q'];
  test('localizedCompact preserves locale patterns with shared decimal rounding', () {
    for (final language in ['en', 'nb', 'fr', 'de', 'ja', 'hi', 'ar', 'fa']) {
      for (final value in [0, -0.0, 0.000001, -0.25, 1, 999, 999.9, 1200, -1234567, 1e9]) {
        final options = en.copyWith(locale: english.locale.copyWith(locale: Locale(language)));
        String expected;
        try {
          expected = NumberFormat.compact(locale: language).format(value == 0 ? 0 : value);
        } catch (error) {
          expect(() => compactFormat(value, options: options), throwsA(predicate((Object thrown) => thrown.runtimeType == error.runtimeType)));
          continue;
        }
        expect(compactFormat(value, options: options), expected, reason: '$language: $value');
      }
      final formatter = NumberFormat.compact(locale: language, explicitSign: true)
        ..minimumFractionDigits = 2
        ..maximumFractionDigits = 2;
      expect(
        compactFormat(
          1234,
          options: en.copyWith(
            locale: english.locale.copyWith(locale: Locale(language)),
            precision: const CompactPrecision.fraction(minimum: 2, maximum: 2),
            explicitSign: true,
          ),
        ),
        formatter.format(1234),
      );
    }
  });

  test('every narrow interval and localized digits, separators and signs', () {
    for (var i = 0; i < narrowCompact.overrides.length; i++) {
      final interval = narrowCompact.overrides[i];
      expect(render(math.pow(interval.scale.base.toDouble(), interval.scale.power)), '1${narrowSymbols[i]}');
      expect(render(-math.pow(interval.scale.base.toDouble(), interval.scale.power)), '-1${narrowSymbols[i]}');
    }
    expect(render(1200), '1.2k');
    expect(render(1e9), '1B');
    expect(render(1e-6), '1µ');
    expect(render(1234567, locale: english.locale.copyWith(locale: Locale('nb'))), '1,23M');
    final persian = NumberFormat.decimalPattern('fa')..maximumFractionDigits = 2;
    expect(render(1234, locale: english.locale.copyWith(locale: Locale('fa'))), '${persian.format(1.23)}k');
    expect(render(1200, sign: true), '+1.2k');
    expect(render(-1200, sign: true), '-1.2k');
    expect(render(-0.0), '0');
    expect(render(0, sign: true), '+0');
  });

  test('rounding promotes across scales and preserves precision, padding and signs', () {
    expect(render(1200, precision: const CompactPrecision.significant(minimum: 3, maximum: 3)), '1.20k');
    expect(render(1200, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2)), '1.20k');
    expect(render(1250, precision: const CompactPrecision.fraction(maximum: 1)), '1.3k');
    expect(render(-1250, precision: const CompactPrecision.fraction(maximum: 1)), '-1.3k');
    expect(render(999950), '1M');
    expect(render(-999950), '-1M');
    expect(render(0.99995), '1');
    expect(render(0.00099995), '1m');
    expect(render(1234567, precision: const CompactPrecision.significant(maximum: 2)), '1.2M');
    expect(render(1234567, precision: const CompactPrecision.significant(maximum: 1)), '1M');
    expect(render(1000, precision: const CompactPrecision.significant(minimum: 21, maximum: 21)), '1.${'0' * 20}k');
    expect(render(1000, precision: const CompactPrecision.fraction(minimum: 20, maximum: 20)), '1.${'0' * 20}k');
    expect(compactFormat(999950, options: en), '1M');
    expect(render(adjacent(1e6, -1)), '1M');
    expect(render(1e6), '1M');
    expect(render(adjacent(1e6, 1)), '1M');
    expect(render(adjacent(0.001, -1)), '1m');
    expect(render(0.001), '1m');
    expect(render(999499), '999k');
    expect(render(999500), '1M');
    expect(render(999950, sign: true), '+1M');
    expect(render(999950, precision: const CompactPrecision.significant(maximum: 5)), '999.95k');
    expect(render(999999, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2)), '1.00M');
    expect(
      render(
        -999999,
        precision: const CompactPrecision.fraction(minimum: 2, maximum: 2),
        locale: english.locale.copyWith(locale: Locale('nb')),
      ),
      '−1,00M',
    );
    expect(render(999500, precision: const CompactPrecision.significant(minimum: 3, maximum: 3)), '1.00M');
  });

  test('promotion reaches every narrow boundary without floating point multiplication drift', () {
    for (var i = 1; i < narrowCompact.overrides.length; i++) {
      final interval = narrowCompact.overrides[i];
      final value = adjacent(math.pow(interval.scale.base.toDouble(), interval.scale.power).toDouble(), -1);
      expect(render(value), '1${narrowSymbols[i]}', reason: '${interval.scale.base}^${interval.scale.power}');
      expect(render(-value), '-1${narrowSymbols[i]}', reason: '${interval.scale.base}^${interval.scale.power}');
    }
    final value = adjacent(1e33, -1);
    expect(render(value), '1${'0' * 21}T');
  });

  test('precision validation applies even to callbacks and special values', () {
    for (final precision in [
      const CompactPrecision.significant(maximum: 0),
      const CompactPrecision.significant(maximum: 1001),
      const CompactPrecision.fraction(minimum: -1, maximum: 2),
      const CompactPrecision.fraction(minimum: 3, maximum: 2),
      const CompactPrecision.fraction(maximum: 1001),
    ]) {
      for (final value in [0, double.nan, 1000]) {
        expect(
          () => compactFormat(
            value,
            options: en.copyWith(
              precision: precision,
              format: CompactFormatDefinition(formatter: (_) => 'custom'),
            ),
          ),
          throwsArgumentError,
        );
      }
    }
  });

  test('special values use localized decimals; narrow extremes delegate unchanged', () {
    for (final language in ['en', 'nb', 'fr', 'de', 'ja', 'hi', 'ar', 'fa']) {
      for (final format in [localizedCompact, narrowCompact]) {
        for (final value in [double.nan, double.infinity, double.negativeInfinity]) {
          expect(
            compactFormat(
              value,
              options: en.copyWith(
                locale: english.locale.copyWith(locale: Locale(language)),
                format: format,
              ),
            ),
            NumberFormat.decimalPattern(language).format(value),
          );
        }
      }
    }
    for (final value in [double.minPositive, double.maxFinite, -double.maxFinite, 1e-31, 1e33]) {
      expect(render(value), compactFormat(value, options: en));
    }
    for (final value in [9007199254740991, 9007199254740992, 9007199254740992 + 2]) {
      expect(render(value), '9.01P');
    }
    expect(render(int.parse('-9223372036854775808')), '-9.22E');
  });

  test('option merging and clearing is field-wise with direct format references', () {
    final options = en.copyWith(format: narrowCompact, explicitSign: true, precision: const CompactPrecision.significant(maximum: 2));
    final merged = options.merge(CompactFormatOptions(locale: english.locale.copyWith(locale: Locale('nb')), explicitSign: false));
    expect(merged.format, same(narrowCompact));
    expect(merged.locale, english.locale.copyWith(locale: const Locale('nb')));
    expect(merged.precision, options.precision);
    expect(merged.explicitSign, false);
    expect(options.copyWith(), options);
    expect(options.copyWith().hashCode, options.hashCode);
    expect(options.copyWith(locale: null, format: null, precision: null, explicitSign: null), const CompactFormatOptions());
  });

  test('callbacks receive resolved locale and original input; errors propagate', () {
    final definition = CompactFormatDefinition(formatter: (context) => '${context.locale}:${context.value}');
    for (final entry in {const Locale('zz', 'ZZ'): 'en', const Locale('nb', 'ZZ'): 'nb', const Locale('en', 'US'): 'en_US'}.entries) {
      expect(
        compactFormat(
          1234,
          options: en.copyWith(
            locale: english.locale.copyWith(locale: entry.key),
            format: definition,
          ),
        ),
        '${entry.value}:1234',
      );
      expect(
        compactFormat(
          1234,
          options: en.copyWith(locale: english.locale.copyWith(locale: entry.key)),
        ),
        NumberFormat.compact(locale: entry.value).format(1234),
      );
    }
    expect(compactFormat(1), '1');
    expect(
      () => compactFormat(
        1,
        options: en.copyWith(format: CompactFormatDefinition(formatter: (_) => throw StateError('visible'))),
      ),
      throwsStateError,
    );
  });
}
