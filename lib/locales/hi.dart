import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import '../src/formatter.dart';
import 'en.dart' as en;

/// Hindi abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('hi'),
  labels: {
    CompactLabel.thousand: 'हज़ार',
    CompactLabel.million: 'M',
    CompactLabel.billion: 'अ॰',
    CompactLabel.trillion: 'T',
    CompactLabel.byte: 'बाइट',
    CompactLabel.millimetre: 'मि॰मी॰',
    CompactLabel.centimetre: 'सें॰मी॰',
    CompactLabel.metre: 'मी',
    CompactLabel.kilometre: 'कि॰मी॰',
    CompactLabel.squareCentimetre: 'व॰ सें॰',
    CompactLabel.squareMetre: 'वर्ग मी॰',
    CompactLabel.squareKilometre: 'वर्ग कि॰मी॰',
    CompactLabel.cubicCentimetre: 'घन सें॰ मी॰',
    CompactLabel.cubicMetre: 'घन मी॰',
    CompactLabel.cubicKilometre: 'घन कि॰मी॰',
    CompactLabel.millilitre: 'मि॰ ली॰',
    CompactLabel.centilitre: 'सें॰ली॰',
    CompactLabel.decilitre: 'डे॰ली॰',
    CompactLabel.litre: 'ली॰',
    CompactLabel.hectolitre: 'हे॰ली॰',
    CompactLabel.microgram: 'मा॰ग्रा॰',
    CompactLabel.milligram: 'मि॰ग्रा॰',
    CompactLabel.gram: 'ग्रा॰',
    CompactLabel.kilogram: 'कि॰ग्रा॰',
    CompactLabel.tonne: 'ट',
    const CompactLabel('number.1e5'): 'लाख',
    const CompactLabel('number.1e7'): 'क॰',
    const CompactLabel('number.1e11'): 'ख॰',
    const CompactLabel('number.1e13'): 'नील',
  },
);

/// Returns this locale with customizable labels for 10³, 10⁶, 10⁹ and 10¹².
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'ह', String M = 'M', String B = 'अ॰', String T = 'T'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});

/// Native magnitude intervals from 10³ upward. Merge into a base format
/// with copyWith(overrides: narrowOverrides) to retain its smaller-number rules.
/// The final interval explicitly extends to infinity when merged.
const narrowOverrides = [
  CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 5), scale: CompactPower(power: 3), suffixLabel: CompactLabel.thousand),
  CompactInterval(from: CompactPower(power: 5), to: CompactPower(power: 7), scale: CompactPower(power: 5), suffixLabel: CompactLabel('number.1e5')),
  CompactInterval(from: CompactPower(power: 7), to: CompactPower(power: 9), scale: CompactPower(power: 7), suffixLabel: CompactLabel('number.1e7')),
  CompactInterval(from: CompactPower(power: 9), to: CompactPower(power: 11), scale: CompactPower(power: 9), suffixLabel: CompactLabel.billion),
  CompactInterval(from: CompactPower(power: 11), to: CompactPower(power: 13), scale: CompactPower(power: 11), suffixLabel: CompactLabel('number.1e11')),
  CompactInterval(from: CompactPower(power: 13), to: CompactPower.positiveInfinity, scale: CompactPower(power: 13), suffixLabel: CompactLabel('number.1e13')),
];
