import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Vietnamese abbreviations for compact numbers and units.
final locale = en.locale.copyWith(locale: const Locale('vi'), labels: {CompactLabel.thousand: 'N', CompactLabel.million: 'Tr', CompactLabel.billion: 'T', CompactLabel.trillion: 'NT', CompactLabel.byte: 'byte'});

/// Returns this locale with customizable labels for 10³, 10⁶, 10⁹ and 10¹².
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'N', String M = 'Tr', String B = 'T', String T = 'NT'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
