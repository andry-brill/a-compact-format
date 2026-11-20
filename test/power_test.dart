import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter_test/flutter_test.dart';

CompactPower decimal(num power) => CompactPower(power: power);
CompactPower binary(num power) => CompactPower(base: 1024, power: power);
String render(Object value, CompactFormatDefinition format) => compactFormat(
  value,
  options: CompactFormatOptions(locale: english.locale, format: format),
);

void main() {
  test('powers compare by exact magnitude across bases and negative powers', () {
    expect(binary(1).compareTo(const CompactPower(base: 2, power: 10)), 0);
    expect(binary(1) > decimal(3), isTrue);
    expect(binary(2) > decimal(6), isTrue);
    expect(binary(-1) < decimal(-3), isTrue);
    expect(const CompactPower(base: 1000, power: 3).compareTo(decimal(9)), 0);
    expect(const CompactPower(base: 20, power: 2).compareTo(const CompactPower(base: 400, power: 1)), 0);
    expect(CompactPower.negativeInfinity < decimal(-100000), isTrue);
    expect(CompactPower.positiveInfinity > binary(10000), isTrue);
    expect(binary(1), binary(1));
    expect(binary(1).hashCode, binary(1).hashCode);
    expect(binary(1), isNot(const CompactPower(base: 2, power: 10)));
  });

  test('intervals expose power bounds and an identity scale by default', () {
    const unbounded = CompactInterval();
    expect(unbounded.from, isNull);
    expect(unbounded.to, isNull);
    expect(unbounded.scale, CompactPower.one);
    expect(unbounded, const CompactInterval(scale: CompactPower(power: 0)));
    const interval = CompactInterval(from: CompactPower(base: 1024, power: 1), to: CompactPower(base: 1024, power: 2), scale: CompactPower(base: 1024, power: 1), suffix: ' KiB');
    final equal = CompactInterval(from: binary(1), to: binary(2), scale: binary(1), suffix: ' KiB');
    expect(interval.from, binary(1));
    expect(interval.to, binary(2));
    expect(interval.scale, binary(1));
    expect(interval, equal);
    expect(interval.hashCode, equal.hashCode);
    expect(interval, isNot(CompactInterval(from: binary(1), to: binary(2), scale: decimal(3), suffix: ' KiB')));
  });

  test('invalid powers, infinite scales and nonterminating decimal bases are rejected', () {
    for (final power in [
      const CompactPower(base: 1, power: 0),
      const CompactPower(base: -2, power: 1),
      const CompactPower(base: 3, power: 1),
      const CompactPower(base: 1000000001, power: 1),
      decimal(0.5),
      decimal(double.nan),
      decimal(100001),
      binary(10001),
    ]) {
      expect(() => CompactFormatDefinition(overrides: [CompactInterval(from: power)]), throwsArgumentError);
      expect(() => CompactFormatDefinition(overrides: [CompactInterval(scale: power)]), throwsArgumentError);
    }
    for (final interval in [
      const CompactInterval(from: CompactPower.positiveInfinity),
      const CompactInterval(to: CompactPower.negativeInfinity),
      const CompactInterval(scale: CompactPower.positiveInfinity),
      const CompactInterval(scale: CompactPower.negativeInfinity),
      const CompactInterval(scale: CompactPower(base: 2, power: 1), notation: CompactNotation.scientific()),
    ]) {
      expect(() => CompactFormatDefinition(overrides: [interval]), throwsArgumentError);
    }
  });

  final target = CompactFormatDefinition(
    overrides: [
      CompactInterval(from: decimal(0), to: decimal(3), formatter: (_) => 'A'),
      CompactInterval(from: decimal(3), to: binary(1), formatter: (_) => 'B'),
      CompactInterval(from: binary(1), to: binary(2), formatter: (_) => 'C'),
    ],
    formatter: (_) => 'gap',
  );

  test('merge omission finds closest strict boundary by value, not exponent or base', () {
    final lower = target.copyWith(
      overrides: [const CompactInterval(to: CompactPower(base: 2, power: 10), suffix: ' override')],
    );
    expect(lower.overrides[1].from, decimal(3));
    expect(render(1000, lower), '1000 override');
    expect(render(1024, lower), 'C');
    final upper = target.copyWith(
      overrides: [const CompactInterval(from: CompactPower(base: 2, power: 10), suffix: ' override')],
    );
    expect(upper.overrides.last.to, binary(2));
    expect(render(1000, upper), 'B');
    expect(render(2048, upper), '2050 override');
    expect(render(1048576, upper), 'gap');
  });

  test('explicit open ends replace whole tails; missing distant bounds infer open ends', () {
    final lower = target.copyWith(
      overrides: [CompactInterval(from: CompactPower.negativeInfinity, to: binary(1), formatter: (_) => 'small')],
    );
    expect(render(Decimal.parse('1e-100'), lower), 'small');
    expect(render(1024, lower), 'C');
    final upper = target.copyWith(
      overrides: [CompactInterval(from: decimal(3), to: CompactPower.positiveInfinity, formatter: (_) => 'large')],
    );
    expect(render(BigInt.from(10).pow(400), upper), 'large');
    expect(render(1, upper), 'A');
    expect(target.copyWith(overrides: [CompactInterval(to: decimal(-1))]).overrides.first.from, CompactPower.negativeInfinity);
    expect(target.copyWith(overrides: [CompactInterval(from: binary(3))]).overrides.last.to, CompactPower.positiveInfinity);
    expect(
      target
          .copyWith(
            overrides: [const CompactInterval(from: CompactPower.negativeInfinity, to: CompactPower.positiveInfinity)],
          )
          .overrides,
      hasLength(1),
    );
    expect(() => target.copyWith(overrides: [const CompactInterval()]), throwsArgumentError);
  });

  test('mixed-base touching ranges are valid; overlap uses the original snapshot', () {
    final touching = [CompactInterval(from: decimal(3), to: binary(1), suffix: ' lower'), CompactInterval(from: const CompactPower(base: 2, power: 10), to: decimal(4), suffix: ' upper')];
    expect(target.copyWith(overrides: touching).overrides, target.copyWith(overrides: touching.reversed).overrides);
    final overlapping = [const CompactInterval(from: CompactPower(base: 2, power: 10), to: CompactPower(base: 2, power: 11)), const CompactInterval(to: CompactPower(base: 2, power: 12))];
    // The second override must still infer 1024, not the new boundary 2048.
    expect(() => target.copyWith(overrides: overlapping), throwsArgumentError);
    expect(() => target.copyWith(overrides: overlapping.reversed), throwsArgumentError);
    expect(
      () => target.copyWith(
        overrides: [CompactInterval(from: binary(1), to: const CompactPower(base: 2, power: 10))],
      ),
      throwsArgumentError,
    );
  });

  test('splitting retains exact scale, notation, callback and subsequent inference', () {
    String? callback(CompactFormattingContext context) => '${context.defaultText}!';
    final source = CompactFormatDefinition(
      base: fileSizeBinary,
      overrides: [CompactInterval(from: binary(1), to: binary(2), scale: binary(1), prefix: 'about ', suffix: ' KiB', notation: const CompactNotation.zeroCount(), formatter: callback)],
    );
    final merged = source.copyWith(
      overrides: [const CompactInterval(from: CompactPower(base: 2, power: 12), to: CompactPower(base: 2, power: 13), suffix: ' custom')],
    );
    expect(merged.overrides, hasLength(3));
    for (final interval in [merged.overrides.first, merged.overrides.last]) {
      expect(interval.scale, binary(1));
      expect(interval.notation, const CompactNotation.zeroCount());
      expect(interval.formatter, same(callback));
      expect(interval.prefix, 'about ');
      expect(interval.suffix, ' KiB');
    }
    expect(render(1536, merged), 'about 1.5 KiB!');
    expect(render(16384, merged), 'about 16 KiB!');
    expect(render(0, merged), '0 B');
    final next = merged.copyWith(overrides: [CompactInterval(to: binary(2))]);
    expect(next.overrides.last.from, const CompactPower(base: 2, power: 13));
    expect(source.overrides, hasLength(1));
  });

  test('constructor inference and scale stay independent across bases', () {
    final format = CompactFormatDefinition(
      overrides: [
        CompactInterval(to: binary(1), suffix: ' B'),
        CompactInterval(scale: decimal(3), suffix: ' thousand'),
        CompactInterval(from: binary(2), scale: binary(2), suffix: ' MiB'),
      ],
    );
    expect(render(1536, format), '1.54 thousand');
    expect(render(-1536, format), '-1.54 thousand');
    expect(render(1048576, format), '1 MiB');
    final fractional = CompactFormatDefinition(overrides: [CompactInterval(scale: binary(-1))]);
    expect(render(Decimal.parse('0.001953125'), fractional), '2');
    expect(render(BigInt.from(2).pow(400), CompactFormatDefinition(overrides: [const CompactInterval(scale: CompactPower(base: 2, power: 400))])), '1');
  });
}
