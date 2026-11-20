import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final en = CompactFormatOptions(locale: english.locale);
String render(num value, CompactFormatDefinition definition, {CompactFormatOptions? options}) => compactFormat(value, options: en.copyWith(format: definition).merge(options));

void main() {
  test('single override promotes out of its half-open bounds to the base', () {
    var calls = 0;
    final definition = CompactFormatDefinition(
      base: localizedCompact,
      overrides: [
        CompactInterval(
          from: CompactPower(power: 6),
          to: CompactPower(power: 9),
          scale: CompactPower(power: 6),
          suffix: ' million',
          formatter: (context) {
            calls++;
            return null;
          },
        ),
      ],
    );
    for (final language in ['en', 'nb']) {
      final options = en.copyWith(locale: english.locale.copyWith(locale: Locale(language)));
      for (final value in [1200, 999950, 1e9, -1e9]) {
        expect(render(value, definition, options: options), NumberFormat.compact(locale: language).format(value));
      }
    }
    expect(calls, 0);
    expect(render(1e6, definition), '1 million');
    expect(render(-1234567, definition), '-1.23 million');
    expect(render(999950000, definition), '1B');
    expect(render(-999950000, definition), '-1B');
    expect(calls, 2);
  });

  test('precedence is local interval, formatter, base, decimal', () {
    final calls = <String>[];
    final base = CompactFormatDefinition(
      formatter: (context) {
        calls.add('base');
        return context.input == 42 ? 'answer' : null;
      },
    );
    final definition = CompactFormatDefinition(
      base: base,
      overrides: [
        CompactInterval(
          from: CompactPower(power: 3),
          to: CompactPower(power: 6),
          scale: CompactPower(power: 3),
          suffix: 'k',
          formatter: (_) {
            calls.add('interval');
            return null;
          },
        ),
      ],
      formatter: (context) {
        calls.add('definition');
        return context.input == 7 ? 'seven' : null;
      },
    );
    expect(render(1200, definition), '1.2k');
    expect(calls, ['interval']);
    calls.clear();
    expect(render(7, definition), 'seven');
    expect(calls, ['definition']);
    calls.clear();
    expect(render(42, definition), 'answer');
    expect(calls, ['definition', 'base']);
    calls.clear();
    expect(render(12, definition), '12');
    expect(calls, ['definition', 'base']);
    expect(render(1234, CompactFormatDefinition()), '1234');
  });

  test('only the final interval callback gets rounded scaled input', () {
    var calls = 0;
    final definition = CompactFormatDefinition(
      base: narrowCompact,
      overrides: [
        CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffix: 'k', formatter: (_) => throw StateError('Provisional callback must not run')),
        CompactInterval(
          from: CompactPower(power: 6),
          to: CompactPower(power: 9),
          scale: CompactPower(power: 6),
          suffix: 'M',
          formatter: (context) {
            calls++;
            expect(context.input, 999950);
            expect(context.value, 1);
            expect(context.locale, 'nb');
            expect(context.interval!.scale, const CompactPower(power: 6));
            expect(context.numberText, '1');
            expect(context.defaultText, '1M');
            return '${context.defaultText} approximately';
          },
        ),
      ],
    );
    expect(
      render(
        999950,
        definition,
        options: en.copyWith(locale: english.locale.copyWith(locale: Locale('nb'))),
      ),
      '1M approximately',
    );
    expect(calls, 1);
    expect(render(1e9, definition), '1B');
    expect(calls, 1);
    final rounded = CompactFormatDefinition(
      overrides: [CompactInterval(scale: CompactPower(power: 3), formatter: (context) => '${context.value}')],
    );
    expect(render(1234, rounded), '1.23');
    expect(render(-1234, rounded), '-1.23');
  });

  test('promotion into a gap uses formatter then base with original input', () {
    final calls = <String>[];
    final definition = CompactFormatDefinition(
      overrides: [
        CompactInterval(to: CompactPower(power: 3), scale: CompactPower(power: 0), formatter: (_) => throw StateError('provisional')),
        CompactInterval(from: CompactPower(power: 6), scale: CompactPower(power: 6), formatter: (_) => throw StateError('must not jump gap')),
      ],
      formatter: (context) {
        calls.add('definition');
        expect(context.input, 999.6);
        expect(context.value, 999.6);
        expect(context.interval, isNull);
        return null;
      },
      base: CompactFormatDefinition(
        formatter: (context) {
          calls.add('base');
          expect(context.value, 999.6);
          return 'original ${context.input}';
        },
      ),
    );
    expect(render(999.6, definition, options: en.copyWith(precision: const CompactPrecision.fraction(maximum: 0))), 'original 999.6');
    expect(calls, ['definition', 'base']);
  });

  test('promotion can be handled by the definition formatter or decimal fallback', () {
    const intervals = [CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffix: 'k')];
    final custom = CompactFormatDefinition(overrides: intervals, formatter: (context) => 'original ${context.input}', base: localizedCompact);
    expect(render(999950, custom), 'original 999950');
    expect(render(999950, CompactFormatDefinition(overrides: intervals)), '999950');
    final derived = CompactFormatDefinition(overrides: intervals, base: narrowCompact);
    expect(render(999950, derived), '1M');
  });

  test('an original gap falls back without probing or rounding a local interval', () {
    final definition = CompactFormatDefinition(
      overrides: [CompactInterval(from: CompactPower(power: 3), scale: CompactPower(power: 3), formatter: (_) => throw StateError('not selected'))],
      formatter: (context) => 'original ${context.input}',
    );
    expect(render(999.6, definition), 'original 999.6');
  });

  test('promotion rescales original input and never demotes for independent divisors', () {
    final definition = CompactFormatDefinition(
      overrides: const [
        CompactInterval(to: CompactPower(power: 3), scale: CompactPower(power: 0)),
        CompactInterval(from: CompactPower(power: 3), scale: CompactPower(power: -1), suffix: ' tenths'),
      ],
    );
    final options = en.copyWith(precision: const CompactPrecision.fraction(maximum: 0));
    expect(render(999.6, definition, options: options), '9996 tenths');
    expect(render(-999.6, definition, options: options), '-9996 tenths');
  });

  test('regional boundaries promote by bounds rather than a fixed factor of 1000', () {
    final definition = CompactFormatDefinition(
      overrides: const [
        CompactInterval(to: CompactPower(power: 3), scale: CompactPower(power: 0)),
        CompactInterval(from: CompactPower(power: 3), scale: CompactPower(power: 3), suffix: 'k'),
        CompactInterval(from: CompactPower(power: 5), scale: CompactPower(power: 5), suffix: 'L'),
        CompactInterval(from: CompactPower(power: 7), scale: CompactPower(power: 7), suffix: 'Cr'),
      ],
    );
    expect(render(99950, definition), '1L');
    expect(render(9995000, definition), '1Cr');
    expect(render(-99950, definition), '-1L');
  });

  test('inner missing endpoints infer only from explicit local neighbours', () {
    final definition = CompactFormatDefinition(
      overrides: const [
        CompactInterval(to: CompactPower(power: 3), scale: CompactPower(power: 0)),
        CompactInterval(scale: CompactPower(power: 3), suffix: 'k'),
        CompactInterval(from: CompactPower(power: 6), scale: CompactPower(power: 6), suffix: 'M'),
      ],
    );
    expect(render(0.1, definition), '0.1');
    expect(render(999, definition), '999');
    expect(render(1000, definition), '1k');
    expect(render(1e6, definition), '1M');
    expect(render(1e12, definition), '1000000M');
    expect(definition.overrides[1].from, isNull);
    expect(definition.overrides[1].to, isNull);
  });

  test('open outer bounds and explicit gaps delegate as declared', () {
    final definition = CompactFormatDefinition(
      base: narrowCompact,
      overrides: const [
        CompactInterval(to: CompactPower(power: 0), scale: CompactPower(power: 0)),
        CompactInterval(from: CompactPower(power: 6), scale: CompactPower(power: 6), suffix: ' million'),
      ],
    );
    expect(render(1e-6, definition), '0.000001');
    expect(render(1200, definition), '1.2k');
    expect(render(1e9, definition), '1000 million');
    final scaled = CompactFormatDefinition(
      overrides: const [CompactInterval(from: CompactPower(power: 5), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffix: ' thousand')],
    );
    expect(render(123456, scaled), '123 thousand');
  });

  test('ambiguous, overlapping, reversed and invalid intervals fail construction', () {
    for (final intervals in <List<CompactInterval>>[
      [const CompactInterval(from: CompactPower(power: 3), scale: CompactPower(power: 3)), const CompactInterval(to: CompactPower(power: 9), scale: CompactPower(power: 6))],
      [const CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 7), scale: CompactPower(power: 3)), const CompactInterval(from: CompactPower(power: 6), to: CompactPower(power: 9), scale: CompactPower(power: 6))],
      [const CompactInterval(from: CompactPower(power: 6), to: CompactPower(power: 9), scale: CompactPower(power: 6)), const CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3))],
      [const CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 3), scale: CompactPower(power: 3))],
      [const CompactInterval(scale: CompactPower(power: 100001))],
      [const CompactInterval(scale: CompactPower(power: -100001))],
      [const CompactInterval(from: CompactPower(power: 100001), scale: CompactPower(power: 0))],
      [const CompactInterval(to: CompactPower(power: 100001), scale: CompactPower(power: 0))],
      [const CompactInterval(from: CompactPower(power: -100001), scale: CompactPower(power: 0))],
      [const CompactInterval(to: CompactPower(power: -100001), scale: CompactPower(power: 0))],
    ]) {
      expect(() => CompactFormatDefinition(overrides: intervals), throwsArgumentError);
    }
  });

  test('immutable definitions compose by direct reference', () {
    final intervals = [const CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffix: 'k')];
    final definition = CompactFormatDefinition(base: localizedCompact, overrides: intervals, formatter: (_) => 'custom');
    intervals.clear();
    expect(definition.overrides, hasLength(1));
    expect(() => definition.overrides.clear(), throwsUnsupportedError);
    final derived = CompactFormatDefinition(
      base: definition,
      overrides: const [CompactInterval(from: CompactPower(power: 6), to: CompactPower(power: 9), scale: CompactPower(power: 6), suffix: ' million')],
    );
    expect(derived.base, same(definition));
    expect(render(1200, derived), '1.2k');
    expect(render(1234567, derived), '1.23 million');
    expect(render(42, derived), 'custom');
    const equal = CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffix: 'k');
    expect(definition.overrides.single, equal);
    expect(definition.overrides.single.hashCode, equal.hashCode);
  });

  test('affixes preserve independent spacing and callbacks return complete text', () {
    final definition = CompactFormatDefinition(
      overrides: const [CompactInterval(scale: CompactPower(power: 3), prefix: 'about ', suffix: '\u00a0thousand')],
    );
    expect(render(1234, definition), 'about 1.23\u00a0thousand');
    expect(render(-1234, definition), 'about -1.23\u00a0thousand');
    final replacement = CompactFormatDefinition(
      base: localizedCompact,
      overrides: [CompactInterval(scale: CompactPower(power: 3), prefix: 'unused', suffix: 'unused', formatter: (_) => '')],
    );
    expect(render(1234, replacement), '');
  });

  test('zero and nonfinite values bypass both callback locations', () {
    final definition = CompactFormatDefinition(
      overrides: [CompactInterval(scale: CompactPower(power: 0), suffix: ' units', formatter: (_) => throw StateError('interval'))],
      formatter: (_) => throw StateError('definition'),
    );
    for (final value in [0, -0.0, double.nan, double.infinity, double.negativeInfinity]) {
      expect(render(value, definition), NumberFormat.decimalPattern('en').format(value == 0 ? 0 : value));
    }
    expect(render(-0.0, definition, options: en.copyWith(explicitSign: true, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))), '+0.00');
    final roundedZero = CompactFormatDefinition(
      overrides: const [CompactInterval(scale: CompactPower(power: 3), suffix: 'k')],
    );
    expect(render(-0.01, roundedZero, options: en.copyWith(precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))), '0.00k');
  });

  test('callback exceptions propagate without fallback', () {
    for (final definition in [
      CompactFormatDefinition(base: localizedCompact, formatter: (_) => throw StateError('definition')),
      CompactFormatDefinition(
        base: localizedCompact,
        overrides: [CompactInterval(scale: CompactPower(power: 0), formatter: (_) => throw StateError('interval'))],
      ),
    ]) {
      expect(() => render(1, definition), throwsStateError);
    }
  });

  test('extreme scaling stays exact beyond double range', () {
    final overflow = CompactFormatDefinition(overrides: const [CompactInterval(scale: CompactPower(power: -308))]);
    expect(render(double.maxFinite, overflow), '18${'0' * 615}');
    final underflow = CompactFormatDefinition(
      overrides: const [CompactInterval(scale: CompactPower(power: 308), suffix: 'x')],
    );
    expect(render(-double.minPositive, underflow), '-0.${'0' * 631}5x');
    final large = CompactFormatDefinition(
      overrides: const [CompactInterval(from: CompactPower(power: 308), to: CompactPower(power: 309), scale: CompactPower(power: 308), suffix: 'x')],
    );
    expect(render(1e308, large), '1x');
    final roundingOverflow = CompactFormatDefinition(overrides: const [CompactInterval(scale: CompactPower(power: 0))]);
    expect(render(double.maxFinite, roundingOverflow, options: en.copyWith(precision: const CompactPrecision.significant(maximum: 1))), '2${'0' * 308}');
  });
}
