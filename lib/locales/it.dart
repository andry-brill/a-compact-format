import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Italian abbreviations with international symbols for shared units.
final locale = en.locale.copyWith(
  locale: const Locale('it'),
  labels: {
    CompactLabel.thousand: 'K',
    CompactLabel.million: 'Mln',
    CompactLabel.billion: 'Mld',
    CompactLabel.trillion: 'Bln',
    CompactLabel.microlitre: 'µl',
    CompactLabel.millilitre: 'ml',
    CompactLabel.centilitre: 'cl',
    CompactLabel.decilitre: 'dl',
    CompactLabel.litre: 'l',
    CompactLabel.hectolitre: 'hl',
    CompactLabel.kilolitre: 'kl',
    CompactLabel.byte: 'byte',
  },
);

/// Returns this locale with short, customizable magnitude labels for narrow displays.
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'K', String M = 'M', String B = 'Md', String T = 'B'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
