import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Swedish abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('sv'),
  labels: {
    CompactLabel.thousand: 'tn',
    CompactLabel.million: 'mn',
    CompactLabel.billion: 'md',
    CompactLabel.trillion: 'bn',
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
CompactLocale narrow({String k = 'tn', String M = 'mn', String B = 'md', String T = 'bn'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
