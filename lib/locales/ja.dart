import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import '../src/formatter.dart';
import 'en.dart' as en;

/// Japanese abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('ja'),
  labels: {
    CompactLabel.thousand: 'k',
    CompactLabel.million: 'M',
    CompactLabel.billion: 'B',
    CompactLabel.trillion: '兆',
    CompactLabel.byte: 'byte',
    CompactLabel.kilobyte: 'KB',
    CompactLabel.millilitre: 'ml',
    const CompactLabel('number.1e4'): '万',
    const CompactLabel('number.1e8'): '億',
    const CompactLabel('number.1e16'): '京',
  },
);

/// Returns this locale with customizable labels for 10³, 10⁶, 10⁹ and 10¹².
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'k', String M = 'M', String B = 'B', String T = '兆'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});

/// Native magnitude intervals from 10⁴ upward. Merge into a base format
/// with copyWith(overrides: narrowOverrides) to retain its smaller-number rules.
/// The final interval explicitly extends to infinity when merged.
const narrowOverrides = [
  CompactInterval(from: CompactPower(power: 4), to: CompactPower(power: 8), scale: CompactPower(power: 4), suffixLabel: CompactLabel('number.1e4')),
  CompactInterval(from: CompactPower(power: 8), to: CompactPower(power: 12), scale: CompactPower(power: 8), suffixLabel: CompactLabel('number.1e8')),
  CompactInterval(from: CompactPower(power: 12), to: CompactPower(power: 16), scale: CompactPower(power: 12), suffixLabel: CompactLabel.trillion),
  CompactInterval(from: CompactPower(power: 16), to: CompactPower.positiveInfinity, scale: CompactPower(power: 16), suffixLabel: CompactLabel('number.1e16')),
];
