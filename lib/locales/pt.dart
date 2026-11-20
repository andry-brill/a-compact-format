import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Brazilian Portuguese abbreviations for compact numbers and units.
final locale = en.locale.copyWith(
  locale: const Locale('pt', 'BR'),
  labels: {
    CompactLabel.thousand: 'mil',
    CompactLabel.million: 'mi',
    CompactLabel.billion: 'bi',
    CompactLabel.trillion: 'tri',
    CompactLabel.byte: 'bytes',
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
CompactLocale narrow({String k = 'k', String M = 'M', String B = 'B', String T = 'T'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
