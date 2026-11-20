import 'package:flutter/foundation.dart';

import '../locales/en.dart' as en;
import 'formats.dart';
import 'formatter.dart';
import 'locale.dart';

/// Rounding of discarded decimal digits, independent of notation and precision.
enum CompactRounding { halfAwayFromZero, halfEven, towardZero, floor, ceil }

/// Precision is validated at runtime when resolved, including const instances.
@immutable
class CompactPrecision {
  final bool isSignificant;
  final int minimum;
  final int maximum;
  const CompactPrecision.significant({this.minimum = 1, required this.maximum}) : isSignificant = true;
  const CompactPrecision.fraction({this.minimum = 0, required this.maximum}) : isSignificant = false;

  /// Retains the precision mode and replaces the requested bounds.
  CompactPrecision copyWith({int? minimum, int? maximum}) =>
      isSignificant ? CompactPrecision.significant(minimum: minimum ?? this.minimum, maximum: maximum ?? this.maximum) : CompactPrecision.fraction(minimum: minimum ?? this.minimum, maximum: maximum ?? this.maximum);

  /// Rejects invalid configurations in release builds too.
  void validate() {
    final lower = isSignificant ? 1 : 0;
    const upper = 1000;
    if (minimum < lower || maximum > upper || minimum > maximum) {
      throw ArgumentError('Precision must satisfy $lower <= minimum <= maximum <= $upper.');
    }
  }

  @override
  bool operator ==(Object other) => other is CompactPrecision && isSignificant == other.isSignificant && minimum == other.minimum && maximum == other.maximum;
  @override
  int get hashCode => Object.hash(isSignificant, minimum, maximum);
}

const _keep = Object();

/// Nullable fields inherit from a provider or defaults.
@immutable
class CompactFormatOptions {
  final CompactLocale? locale;
  final CompactFormatDefinition? format;
  final CompactPrecision? precision;
  final bool? explicitSign;
  final CompactRounding? rounding;
  final CompactFormatter? _fallbackFormatter;

  /// Final fallback after the selected definition's intervals, formatter,
  /// notation and base. Also handles zero when formatZero is false.
  /// Returns defaultFallbackFormatter when no override is stored.
  /// A null constructor or copyWith argument clears the stored override,
  /// allowing merge to inherit a parent's callback.
  /// Return null for ordinary decimals. Context formatting helpers remain
  /// available inside this callback without invoking the fallback again.
  CompactFormatter get fallbackFormatter => _fallbackFormatter ?? defaultFallbackFormatter;

  const CompactFormatOptions({this.locale, this.format, this.precision, this.explicitSign, this.rounding, this._fallbackFormatter});
  static final defaults = CompactFormatOptions(locale: en.locale, format: localizedCompact, explicitSign: false, rounding: CompactRounding.halfAwayFromZero);

  CompactFormatOptions merge(CompactFormatOptions? overrides) => CompactFormatOptions(
    locale: overrides?.locale ?? locale,
    format: overrides?.format ?? format,
    precision: overrides?.precision ?? precision,
    explicitSign: overrides?.explicitSign ?? explicitSign,
    rounding: overrides?.rounding ?? rounding,
    fallbackFormatter: overrides?._fallbackFormatter ?? _fallbackFormatter,
  );

  /// Omitted fields are retained; explicit null clears a local override.
  CompactFormatOptions copyWith({Object? locale = _keep, Object? format = _keep, Object? precision = _keep, Object? explicitSign = _keep, Object? rounding = _keep, Object? fallbackFormatter = _keep}) => CompactFormatOptions(
    locale: identical(locale, _keep) ? this.locale : locale as CompactLocale?,
    format: identical(format, _keep) ? this.format : format as CompactFormatDefinition?,
    precision: identical(precision, _keep) ? this.precision : precision as CompactPrecision?,
    explicitSign: identical(explicitSign, _keep) ? this.explicitSign : explicitSign as bool?,
    rounding: identical(rounding, _keep) ? this.rounding : rounding as CompactRounding?,
    fallbackFormatter: identical(fallbackFormatter, _keep) ? _fallbackFormatter : fallbackFormatter as CompactFormatter?,
  );
  @override
  bool operator ==(Object other) =>
      other is CompactFormatOptions && locale == other.locale && format == other.format && precision == other.precision && explicitSign == other.explicitSign && rounding == other.rounding && _fallbackFormatter == other._fallbackFormatter;
  @override
  int get hashCode => Object.hash(locale, format, precision, explicitSign, rounding, _fallbackFormatter);
}
