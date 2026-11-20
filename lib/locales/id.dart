import 'package:flutter/widgets.dart' show Locale;

import '../src/labels.dart';
import '../src/locale.dart';
import 'en.dart' as en;

/// Indonesian abbreviations for compact numbers and units.
final locale = en.locale.copyWith(locale: const Locale('id'), labels: {CompactLabel.thousand: 'rb', CompactLabel.million: 'jt', CompactLabel.billion: 'M', CompactLabel.trillion: 'T', CompactLabel.byte: 'byte'});

/// Returns this locale with customizable labels for 10³, 10⁶, 10⁹ and 10¹².
// ignore: non_constant_identifier_names
CompactLocale narrow({String k = 'rb', String M = 'jt', String B = 'M', String T = 'T'}) => locale.copyWith(labels: {CompactLabel.thousand: k, CompactLabel.million: M, CompactLabel.billion: B, CompactLabel.trillion: T});
