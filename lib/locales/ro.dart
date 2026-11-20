import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Romanian abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('ro'),
  labels: {
    CompactLabel.thousand: 'K',
    CompactLabel.million: 'mil.',
    CompactLabel.billion: 'mld.',
    CompactLabel.trillion: 'tril.',
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
CompactLocale narrow({String k = 'K', String M = 'M', String B = 'Md', String T = 'T'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
