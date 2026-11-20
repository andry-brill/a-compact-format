import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import 'labels.dart';

/// One numeric locale and its abbreviation labels. No registry or cross-language
/// fallback is used. Import a bundled locale or construct a complete custom one.
@immutable
final class CompactLocale {
  final Locale locale;
  final Map<CompactLabel, String> labels;

  CompactLocale({required this.locale, required Map<CompactLabel, String> labels}) : labels = Map.unmodifiable(labels);

  /// Override selected labels within this configuration; omitted keys stay as
  /// they are. An empty string hides a label. Locale changes are explicit and
  /// retain the existing labels, e.g. for a regional numeric convention.
  CompactLocale copyWith({Locale? locale, Map<CompactLabel, String>? labels}) => CompactLocale(locale: locale ?? this.locale, labels: {...this.labels, ...?labels});

  /// Missing keys use only the interval's literal fallback, never another locale.
  String resolve(CompactLabel label, {String fallback = ''}) => labels[label] ?? fallback;

  @override
  bool operator ==(Object other) => other is CompactLocale && locale == other.locale && mapEquals(labels, other.labels);
  @override
  int get hashCode => Object.hash(locale, Object.hashAllUnordered(labels.entries.map((entry) => Object.hash(entry.key, entry.value))));
}
