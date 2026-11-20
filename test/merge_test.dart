import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter_test/flutter_test.dart';

const negativeInfinity = double.negativeInfinity;
const positiveInfinity = double.infinity;

String render(num value, CompactFormatDefinition format) => compactFormat(
  value,
  options: CompactFormatOptions(locale: english.locale, format: format),
);
List<(num?, num?)> bounds(CompactFormatDefinition format) => [for (final interval in format.overrides) (interval.from?.power, interval.to?.power)];

void main() {
  final target = CompactFormatDefinition(
    overrides: [
      CompactInterval(from: CompactPower(power: -6), to: CompactPower(power: -3), scale: CompactPower(power: -6), formatter: (_) => 'A'),
      CompactInterval(from: CompactPower(power: -3), to: CompactPower(power: 0), scale: CompactPower(power: -3), formatter: (_) => 'B'),
      CompactInterval(from: CompactPower(power: 0), to: CompactPower(power: 3), scale: CompactPower(power: 0), formatter: (_) => 'C'),
      CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), formatter: (_) => 'D'),
    ],
    formatter: (_) => 'fallback',
  );
  CompactInterval replacement({num? from, num? to}) => CompactInterval(
    from: from == null ? null : CompactPower(power: from),
    to: to == null ? null : CompactPower(power: to),
    scale: CompactPower(power: 0),
    formatter: (_) => 'override',
  );

  final cases = <({String name, num? from, num? to, List<(num, num)> ranges, Map<num, String> samples})>[
    (name: 'omitted lower bound replaces only the preceding interval', from: null, to: 0, ranges: [(-6, -3), (-3, 0), (0, 3), (3, 6)], samples: {1e-6: 'A', 1e-3: 'override', 1: 'C'}),
    (name: 'omitted upper bound replaces only the following interval', from: -6, to: null, ranges: [(-6, -3), (-3, 0), (0, 3), (3, 6)], samples: {1e-7: 'fallback', 1e-6: 'override', 1e-3: 'B'}),
    (name: 'negative infinity replaces all smaller intervals', from: negativeInfinity, to: 0, ranges: [(negativeInfinity, 0), (0, 3), (3, 6)], samples: {1e-36: 'override', 1e-6: 'override', 0.001: 'override', 1: 'C'}),
    (name: 'positive infinity replaces all larger intervals', from: 0, to: positiveInfinity, ranges: [(-6, -3), (-3, 0), (0, positiveInfinity)], samples: {0.001: 'B', 1: 'override', 1e9: 'override'}),
    (name: 'no earlier boundary infers negative infinity', from: null, to: -7, ranges: [(negativeInfinity, -7), (-6, -3), (-3, 0), (0, 3), (3, 6)], samples: {1e-8: 'override', 1e-7: 'fallback', 1e-6: 'A'}),
    (name: 'no later boundary infers positive infinity', from: 7, to: null, ranges: [(-6, -3), (-3, 0), (0, 3), (3, 6), (7, positiveInfinity)], samples: {1e5: 'D', 1e6: 'fallback', 1e7: 'override'}),
    (name: 'inferred boundary trims an existing interval', from: null, to: -4, ranges: [(-6, -4), (-4, -3), (-3, 0), (0, 3), (3, 6)], samples: {1e-6: 'override', 1e-4: 'A', 1e-3: 'B'}),
    (name: 'explicit interior range splits an existing interval', from: -5, to: -4, ranges: [(-6, -5), (-5, -4), (-4, -3), (-3, 0), (0, 3), (3, 6)], samples: {1e-6: 'A', 1e-5: 'override', 1e-4: 'A'}),
    (name: 'both infinities replace the entire format range', from: negativeInfinity, to: positiveInfinity, ranges: [(negativeInfinity, positiveInfinity)], samples: {1e-36: 'override', 1e-6: 'override', 1: 'override', 1e12: 'override'}),
  ];
  for (final sample in cases) {
    test(sample.name, () {
      final result = target.copyWith(
        overrides: [replacement(from: sample.from, to: sample.to)],
      );
      expect(bounds(result), sample.ranges);
      for (final entry in sample.samples.entries) {
        expect(render(entry.key, result), entry.value, reason: '${entry.key}');
        expect(render(-entry.key, result), entry.value, reason: '-${entry.key}');
      }
      expect(bounds(target), [(-6, -3), (-3, 0), (0, 3), (3, 6)]);
      expect(render(1e-6, target), 'A');
    });
  }

  test('inference includes both kinds of boundaries and preserves gaps', () {
    final gapped = CompactFormatDefinition(overrides: [replacement(from: -6, to: -3), replacement(from: 0, to: 3)], formatter: (_) => 'gap');
    final fromEnd = gapped.copyWith(overrides: [replacement(to: -1)]);
    expect(bounds(fromEnd), [(-6, -3), (-3, -1), (0, 3)]);
    expect(render(0.01, fromEnd), 'override');
    expect(render(0.1, fromEnd), 'gap');
    final toStart = gapped.copyWith(overrides: [replacement(from: -2)]);
    expect(bounds(toStart), [(-6, -3), (-2, 0), (0, 3)]);
    expect(render(0.001, toStart), 'gap');
    expect(render(0.01, toStart), 'override');
  });

  test('batch inference uses the original target and is order independent', () {
    final changes = [replacement(to: -4), replacement(from: -3, to: -2)];
    final forward = target.copyWith(overrides: changes);
    final reverse = target.copyWith(overrides: changes.reversed);
    expect(bounds(forward), [(-6, -4), (-4, -3), (-3, -2), (-2, 0), (0, 3), (3, 6)]);
    expect(forward.overrides, reverse.overrides);
    for (final value in [1e-6, 1e-4, 1e-3, 1e-2, 1, 1e3]) {
      expect(render(value, forward), render(value, reverse));
    }
    // If inferred sequentially, -5 would incorrectly become the new lower
    // boundary of the second change, hiding their overlap in the original target.
    final overlapping = [replacement(from: -6, to: -5), replacement(to: -4)];
    expect(() => target.copyWith(overrides: overlapping), throwsArgumentError);
    expect(() => target.copyWith(overrides: overlapping.reversed), throwsArgumentError);
  });

  test('touching overrides are valid but overlapping overrides are rejected', () {
    final result = target.copyWith(overrides: [replacement(from: -5, to: -4), replacement(from: -4, to: -3)]);
    expect(bounds(result), [(-6, -5), (-5, -4), (-4, -3), (-3, 0), (0, 3), (3, 6)]);
    for (final changes in [
      [replacement(from: -5, to: -3), replacement(from: -4, to: -2)],
      [replacement(from: -5, to: -3), replacement(from: -5, to: -3)],
      [replacement(from: negativeInfinity, to: positiveInfinity), replacement(from: 0, to: 3)],
    ]) {
      expect(() => target.copyWith(overrides: changes), throwsArgumentError);
    }
  });

  test('missing, reversed, fractional, NaN and wrong infinity endpoints fail', () {
    for (final interval in [
      replacement(),
      replacement(from: 0, to: 0),
      replacement(from: 3, to: 0),
      replacement(from: positiveInfinity, to: 0),
      replacement(from: 0, to: negativeInfinity),
      replacement(from: double.nan, to: 0),
      replacement(from: 0, to: double.nan),
      replacement(from: -1.5, to: 0),
      replacement(from: 0, to: 1.5),
      replacement(from: -100001, to: 0),
      replacement(from: 0, to: 100001),
      const CompactInterval(from: CompactPower(power: 0), to: CompactPower(power: 3), scale: CompactPower(power: 100001)),
    ]) {
      expect(() => target.copyWith(overrides: [interval]), throwsArgumentError);
    }
  });

  test('constructor accepts explicit infinities without changing its neighbour inference', () {
    final result = CompactFormatDefinition(
      overrides: [
        replacement(from: negativeInfinity, to: 0),
        replacement(from: 0, to: positiveInfinity),
      ],
    );
    expect(render(1e-36, result), 'override');
    expect(render(1e36, result), 'override');
    for (final interval in [replacement(from: positiveInfinity), replacement(to: negativeInfinity), replacement(from: double.nan), replacement(to: 0.5)]) {
      expect(() => CompactFormatDefinition(overrides: [interval]), throwsArgumentError);
    }
  });

  test('split pieces retain scaling, affixes, callbacks and fallback chain', () {
    final callbackInputs = <Object>[];
    final original = CompactFormatDefinition(
      base: localizedCompact,
      formatter: (context) => context.input == 7 ? 'seven' : null,
      overrides: [
        CompactInterval(
          from: CompactPower(power: 3),
          to: CompactPower(power: 9),
          scale: CompactPower(power: 3),
          prefix: 'about ',
          suffix: ' thousand',
          formatter: (context) {
            callbackInputs.add(context.input);
            return '${context.defaultText}!';
          },
        ),
      ],
    );
    final result = original.copyWith(overrides: [replacement(from: 4, to: 5)]);
    expect(bounds(result), [(3, 4), (4, 5), (5, 9)]);
    expect(result.base, same(original.base));
    expect(result.formatter, same(original.formatter));
    for (final interval in [result.overrides.first, result.overrides.last]) {
      expect(interval.scale, const CompactPower(power: 3));
      expect(interval.formatter, same(original.overrides.single.formatter));
      expect(interval.prefix, 'about ');
      expect(interval.suffix, ' thousand');
    }
    expect(render(1200, result), 'about 1.2 thousand!');
    expect(render(12000, result), 'override');
    expect(render(120000, result), 'about 120 thousand!');
    expect(callbackInputs, [1200, 120000]);
    expect(render(7, result), 'seven');
    expect(render(1e9, result), '1B');
  });

  test('resolved original boundaries survive splitting and subsequent merges', () {
    final original = CompactFormatDefinition(
      overrides: const [
        CompactInterval(to: CompactPower(power: 3), scale: CompactPower(power: 0)),
        CompactInterval(scale: CompactPower(power: 3), suffix: 'k'),
        CompactInterval(from: CompactPower(power: 6), scale: CompactPower(power: 6), suffix: 'M'),
      ],
    );
    final result = original.copyWith(overrides: [replacement(from: 4, to: 5)]);
    expect(bounds(result), [(negativeInfinity, 3), (3, 4), (4, 5), (5, 6), (6, positiveInfinity)]);
    expect(render(1e3, result), '1k');
    expect(render(1e5, result), '100k');
    final next = result.copyWith(overrides: [replacement(to: 6)]);
    expect(render(1e3, next), '1k');
    expect(render(1e5, next), 'override');
    expect(render(1e6, next), '1M');
    expect(original.overrides[1].from, isNull);
  });

  test('rounding promotes into the merged interval, using only its callback', () {
    var calls = 0;
    final result = narrowCompact.copyWith(
      overrides: [
        CompactInterval(
          from: CompactPower(power: 6),
          scale: CompactPower(power: 6),
          suffix: ' million',
          formatter: (context) {
            calls++;
            return context.defaultText;
          },
        ),
      ],
    );
    expect(render(999950, result), '1 million');
    expect(render(-999950, result), '-1 million');
    expect(calls, 2);
    expect(render(1e9, result), '1B');
  });

  test('empty targets, no-op copies and immutable snapshots are supported', () {
    expect(target.copyWith(), same(target));
    expect(target.copyWith(overrides: []), same(target));
    expect(bounds(localizedCompact.copyWith(overrides: [replacement(to: 0)])), [(negativeInfinity, 0)]);
    expect(bounds(localizedCompact.copyWith(overrides: [replacement(from: 0)])), [(0, positiveInfinity)]);
    final changes = [replacement(to: 0)];
    final result = target.copyWith(overrides: changes);
    changes.clear();
    expect(render(0.1, result), 'override');
    expect(() => result.overrides.clear(), throwsUnsupportedError);
  });
}
