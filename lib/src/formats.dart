import 'package:decimal/decimal.dart';

import 'formatter.dart';
import 'notation.dart';
import 'labels.dart';

/// CLDR compact patterns supplied by intl, rendered by our exact decimal engine.
final localizedCompact = CompactFormatDefinition(formatter: (context) => context.formatCompact(context.value));

/// Reusable [-infinity, 0) exponent override for subunit decimals with Unicode
/// zero counts. Apply with any format's copyWith(overrides: subscriptOverrides).
/// Explicit negative infinity replaces every smaller-number interval.
const subscriptOverrides = [
  CompactInterval(
    from: CompactPower.negativeInfinity,
    to: CompactPower(power: 0),
    notation: CompactNotation.zeroCount(sides: ZeroCountSides.leading),
  ),
];

/// Convenience composition of localizedCompact with the subscript override.
final subscriptCompact = localizedCompact.copyWith(overrides: subscriptOverrides);

final zeroSubscriptCompact = CompactFormatDefinition(notation: const CompactNotation.zeroCount());
final zeroSuperscriptCompact = CompactFormatDefinition(notation: const CompactNotation.zeroCount(script: CompactScript.superscript));
final scientificCompact = CompactFormatDefinition(notation: const CompactNotation.scientific());
final engineeringCompact = CompactFormatDefinition(notation: const CompactNotation.engineering());

/// Ordinary small decimals, subscript leading zeros, k/M/B, then superscript
/// trailing zeros (the count represents the entire run between the zero markers).
final narrowNatural = CompactFormatDefinition(
  base: zeroSuperscriptCompact,
  overrides: [
    ...subscriptOverrides,
    const CompactInterval(from: CompactPower(power: 0), to: CompactPower(power: 3)),
    const CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffixLabel: CompactLabel.thousand),
    const CompactInterval(from: CompactPower(power: 6), to: CompactPower(power: 9), scale: CompactPower(power: 6), suffixLabel: CompactLabel.million),
    const CompactInterval(from: CompactPower(power: 9), to: CompactPower(power: 12), scale: CompactPower(power: 9), suffixLabel: CompactLabel.billion),
  ],
);

/// SI-inspired intervals in [1e-30, 1e33), with B for billions and µ for micro.
/// Rounding promotes across interval boundaries, e.g. 999950 becomes 1M.
final narrowCompact = CompactFormatDefinition(
  base: localizedCompact,
  overrides: [
    for (final entry in const {
      -30: CompactLabel.quecto,
      -27: CompactLabel.ronto,
      -24: CompactLabel.yocto,
      -21: CompactLabel.zepto,
      -18: CompactLabel.atto,
      -15: CompactLabel.femto,
      -12: CompactLabel.pico,
      -9: CompactLabel.nano,
      -6: CompactLabel.micro,
      -3: CompactLabel.milli,
      0: null,
      3: CompactLabel.thousand,
      6: CompactLabel.million,
      9: CompactLabel.billion,
      12: CompactLabel.trillion,
      15: CompactLabel.quadrillion,
      18: CompactLabel.quintillion,
      21: CompactLabel.sextillion,
      24: CompactLabel.septillion,
      27: CompactLabel.octillion,
      30: CompactLabel.nonillion,
    }.entries)
      CompactInterval(
        from: CompactPower(power: entry.key),
        to: entry.key == 30 ? const CompactPower(power: 33) : null,
        scale: CompactPower(power: entry.key),
        suffixLabel: entry.value,
      ),
  ],
);

/// Binary byte sizes, with exact 1024 steps through YiB. Input is bytes.
final fileSizeBinary = _fileSizes(1024, const [CompactLabel.byte, CompactLabel.kibibyte, CompactLabel.mebibyte, CompactLabel.gibibyte, CompactLabel.tebibyte, CompactLabel.pebibyte, CompactLabel.exbibyte, CompactLabel.zebibyte, CompactLabel.yobibyte]);

/// Decimal byte sizes, with exact 1000 steps through QB. Input is bytes.
final fileSizeDecimal = _fileSizes(1000, const [
  CompactLabel.byte,
  CompactLabel.kilobyte,
  CompactLabel.megabyte,
  CompactLabel.gigabyte,
  CompactLabel.terabyte,
  CompactLabel.petabyte,
  CompactLabel.exabyte,
  CompactLabel.zettabyte,
  CompactLabel.yottabyte,
  CompactLabel.ronnabyte,
  CompactLabel.quettabyte,
]);

/// Metric length. Input is metres; zero retains this input unit.
final lengthMetric = _units(const [
  (CompactPower(power: -6), CompactLabel.micrometre),
  (CompactPower(power: -3), CompactLabel.millimetre),
  (CompactPower(power: -2), CompactLabel.centimetre),
  (CompactPower(power: 0), CompactLabel.metre),
  (CompactPower(power: 3), CompactLabel.kilometre),
], zeroLabel: CompactLabel.metre);

/// Metric area. Input is square metres; zero retains this input unit.
final areaMetric = _units(const [
  (CompactPower(power: -6), CompactLabel.squareMillimetre),
  (CompactPower(power: -4), CompactLabel.squareCentimetre),
  (CompactPower(power: 0), CompactLabel.squareMetre),
  (CompactPower(power: 6), CompactLabel.squareKilometre),
], zeroLabel: CompactLabel.squareMetre);

/// Metric volume. Input is cubic metres; zero retains this input unit.
final volumeMetric = _units(const [
  (CompactPower(power: -9), CompactLabel.cubicMillimetre),
  (CompactPower(power: -6), CompactLabel.cubicCentimetre),
  (CompactPower(power: 0), CompactLabel.cubicMetre),
  (CompactPower(power: 9), CompactLabel.cubicKilometre),
], zeroLabel: CompactLabel.cubicMetre);

/// Metric volume. Input is litres; zero retains this input unit.
final volumeLitres = _units(const [
  (CompactPower(power: -6), CompactLabel.microlitre),
  (CompactPower(power: -3), CompactLabel.millilitre),
  (CompactPower(power: -2), CompactLabel.centilitre),
  (CompactPower(power: -1), CompactLabel.decilitre),
  (CompactPower(power: 0), CompactLabel.litre),
  (CompactPower(power: 2), CompactLabel.hectolitre),
  (CompactPower(power: 3), CompactLabel.kilolitre),
], zeroLabel: CompactLabel.litre);

/// Metric mass. Input is grams; zero retains this input unit.
final massMetric = _units(const [
  (CompactPower(power: -6), CompactLabel.microgram),
  (CompactPower(power: -3), CompactLabel.milligram),
  (CompactPower(power: 0), CompactLabel.gram),
  (CompactPower(power: 3), CompactLabel.kilogram),
  (CompactPower(power: 6), CompactLabel.tonne),
], zeroLabel: CompactLabel.gram);

CompactFormatDefinition _fileSizes(int base, List<CompactLabel> labels) => _units([for (var index = 0; index < labels.length; index++) (CompactPower(base: base, power: index), labels[index])]);

// One interval path for every unit family, including exact scaling, promotion,
// precision and labels. Out-of-range magnitudes retain the nearest end unit.
CompactFormatDefinition _units(List<(CompactPower, CompactLabel)> units, {CompactLabel? zeroLabel}) {
  final zeroFormat = zeroLabel == null
      ? null
      : CompactFormatDefinition(
          formatZero: true,
          overrides: [CompactInterval(suffixLabel: zeroLabel, separator: ' ')],
        );
  return CompactFormatDefinition(
    formatZero: true,
    overrides: [
      for (var index = 0; index < units.length; index++)
        CompactInterval(
          from: index == 0 ? CompactPower.negativeInfinity : units[index].$1,
          to: index == units.length - 1 ? CompactPower.positiveInfinity : units[index + 1].$1,
          scale: units[index].$1,
          suffixLabel: units[index].$2,
          separator: ' ',
          // Zero has no magnitude. Render it through an unscaled interval with
          // the input unit, preserving the same options and label resolver.
          formatter: index == 0 && zeroFormat != null ? (context) => context.decimalInput == Decimal.zero ? compactFormat(0, options: context.options.copyWith(format: zeroFormat)) : null : null,
        ),
    ],
  );
}
