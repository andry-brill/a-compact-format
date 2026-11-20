import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import '../src/formatter.dart';
import 'en.dart' as en;

/// Simplified Chinese abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('zh'),
  labels: {
    CompactLabel.thousand: 'k',
    CompactLabel.million: 'M',
    CompactLabel.billion: 'B',
    CompactLabel.trillion: '万亿',
    CompactLabel.micrometre: '微米',
    CompactLabel.millimetre: '毫米',
    CompactLabel.centimetre: '厘米',
    CompactLabel.metre: '米',
    CompactLabel.kilometre: '公里',
    CompactLabel.squareCentimetre: '平方厘米',
    CompactLabel.squareMetre: '平方米',
    CompactLabel.squareKilometre: '平方公里',
    CompactLabel.cubicCentimetre: '立方厘米',
    CompactLabel.cubicMetre: '立方米',
    CompactLabel.cubicKilometre: '立方千米',
    CompactLabel.millilitre: '毫升',
    CompactLabel.centilitre: '厘升',
    CompactLabel.decilitre: '分升',
    CompactLabel.litre: '升',
    CompactLabel.hectolitre: '公石',
    const CompactLabel('number.1e4'): '万',
    const CompactLabel('number.1e8'): '亿',
  },
);

/// Returns this locale with customizable labels for 10³, 10⁶, 10⁹ and 10¹².
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'k', String M = 'M', String B = 'B', String T = '万亿'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});

/// Native magnitude intervals from 10⁴ upward. Merge into a base format
/// with copyWith(overrides: narrowOverrides) to retain its smaller-number rules.
/// The final interval explicitly extends to infinity when merged.
const narrowOverrides = [
  CompactInterval(from: CompactPower(power: 4), to: CompactPower(power: 8), scale: CompactPower(power: 4), suffixLabel: CompactLabel('number.1e4')),
  CompactInterval(from: CompactPower(power: 8), to: CompactPower(power: 12), scale: CompactPower(power: 8), suffixLabel: CompactLabel('number.1e8')),
  CompactInterval(from: CompactPower(power: 12), to: CompactPower.positiveInfinity, scale: CompactPower(power: 12), suffixLabel: CompactLabel.trillion),
];
