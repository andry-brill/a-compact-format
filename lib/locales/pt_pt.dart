import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// European Portuguese abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('pt', 'PT'),
  labels: {
    CompactLabel.thousand: 'mil',
    CompactLabel.million: 'M',
    CompactLabel.billion: 'mM',
    CompactLabel.trillion: 'Bi',
    CompactLabel.byte: 'byte',
    CompactLabel.microlitre: 'µl',
    CompactLabel.millilitre: 'ml',
    CompactLabel.centilitre: 'cl',
    CompactLabel.decilitre: 'dl',
    CompactLabel.litre: 'l',
    CompactLabel.hectolitre: 'hl',
    CompactLabel.kilolitre: 'kl',
  },
);

/// Returns this locale with customizable labels for 10³, 10⁶, 10⁹ and 10¹².
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'k', String M = 'M', String B = 'mM', String T = 'Bi'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
