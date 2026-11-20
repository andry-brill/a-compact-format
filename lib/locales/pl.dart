import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Polish abbreviations with international symbols for shared units.
final locale = en.locale.copyWith(
  locale: const Locale('pl'),
  labels: {
    CompactLabel.thousand: 'tys.',
    CompactLabel.million: 'mln',
    CompactLabel.billion: 'mld',
    CompactLabel.trillion: 'bln',
    CompactLabel.microlitre: 'µl',
    CompactLabel.millilitre: 'ml',
    CompactLabel.centilitre: 'cl',
    CompactLabel.decilitre: 'dl',
    CompactLabel.litre: 'l',
    CompactLabel.hectolitre: 'hl',
    CompactLabel.kilolitre: 'kl',
  },
);

/// Returns this locale with short, customizable magnitude labels for narrow displays.
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 't', String M = 'M', String B = 'Md', String T = 'B'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
