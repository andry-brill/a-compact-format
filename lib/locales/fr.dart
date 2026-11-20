import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// French abbreviations with international symbols for shared units.
final locale = en.locale.copyWith(
  locale: const Locale('fr'),
  labels: {
    CompactLabel.thousand: 'k',
    CompactLabel.million: 'M',
    CompactLabel.billion: 'Md',
    CompactLabel.trillion: 'Bn',
    CompactLabel.microlitre: 'µl',
    CompactLabel.millilitre: 'ml',
    CompactLabel.centilitre: 'cl',
    CompactLabel.decilitre: 'dl',
    CompactLabel.litre: 'l',
    CompactLabel.hectolitre: 'hl',
    CompactLabel.kilolitre: 'kl',
    CompactLabel.byte: 'o',
    CompactLabel.kilobyte: 'ko',
    CompactLabel.megabyte: 'Mo',
    CompactLabel.gigabyte: 'Go',
    CompactLabel.terabyte: 'To',
    CompactLabel.petabyte: 'Po',
    CompactLabel.exabyte: 'Eo',
    CompactLabel.zettabyte: 'Zo',
    CompactLabel.yottabyte: 'Yo',
    CompactLabel.ronnabyte: 'Ro',
    CompactLabel.quettabyte: 'Qo',
    CompactLabel.kibibyte: 'Kio',
    CompactLabel.mebibyte: 'Mio',
    CompactLabel.gibibyte: 'Gio',
    CompactLabel.tebibyte: 'Tio',
    CompactLabel.pebibyte: 'Pio',
    CompactLabel.exbibyte: 'Eio',
    CompactLabel.zebibyte: 'Zio',
    CompactLabel.yobibyte: 'Yio',
  },
);

/// Returns this locale with short, customizable magnitude labels for narrow displays.
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'k', String M = 'M', String B = 'Md', String T = 'B'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
