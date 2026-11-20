import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// German abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('de'),
  labels: {
    CompactLabel.thousand: 'Tsd.',
    CompactLabel.million: 'Mio.',
    CompactLabel.billion: 'Mrd.',
    CompactLabel.trillion: 'Bio.',
    CompactLabel.byte: 'Byte',
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
CompactLocale narrow({String k = 'Tsd', String M = 'M', String B = 'Md', String T = 'B'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
