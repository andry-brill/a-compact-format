import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Turkish abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('tr'),
  labels: {
    CompactLabel.thousand: 'B',
    CompactLabel.million: 'Mn',
    CompactLabel.billion: 'Mr',
    CompactLabel.trillion: 'Tn',
    CompactLabel.byte: 'bayt',
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
CompactLocale narrow({String k = 'B', String M = 'Mn', String B = 'Mr', String T = 'Tn'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
