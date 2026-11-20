import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart' show compactNumberSymbols;

import 'options.dart';
import 'labels.dart';
import 'notation.dart';

part 'decimal_engine.dart';
part 'power.dart';

/// Formats num, Decimal or BigInt through one decimal rounding engine.
/// Doubles use their shortest decimal representation; lost input precision
/// cannot be recovered. Strings are deliberately not parsed implicitly.
String compactFormat(Object value, {CompactFormatOptions? options}) {
  final resolved = CompactFormatOptions.defaults.merge(options);
  final locale = resolved.locale!;
  resolved.precision?.validate();
  final name = _resolveCompactLocale(locale.locale);
  final special = _specialNumber(value, name, resolved);
  if (special != null) return special;
  final decimal = _DecimalDigits.from(value);
  final context = CompactFormattingContext._(input: decimal.isZero ? 0 : value, exactInput: decimal, exactValue: decimal, locale: name, options: resolved);
  if (decimal.isZero && !resolved.format!.formatZero) return context._fallbackText;
  return resolved.format!._format(context);
}

/// Return complete text, or null to use the default path at this location.
typedef CompactFormatter = String? Function(CompactFormattingContext context);

/// Ordinary localized decimals using the resolved precision, rounding and sign.
/// Pass this function to fallbackFormatter to restore the default explicitly.
String defaultFallbackFormatter(CompactFormattingContext context) => context.formatDecimal(context.input);

/// A half-open input-magnitude range [from, to), with an independent divisor.
/// Missing inner bounds inherit the explicit endpoint of the neighbour.
/// In copyWith overrides, missing bounds infer from the original target.
/// Explicit infinite powers always keep an end open.
@immutable
class CompactInterval {
  final CompactPower? from, to;
  final CompactPower scale;
  final CompactNotation notation;
  final String prefix;
  final String suffix;
  final CompactLabel? prefixLabel, suffixLabel;

  /// Inserted between each nonempty affix and the formatted number.
  final String separator;
  final CompactFormatter? formatter;
  const CompactInterval({this.from, this.to, this.scale = CompactPower.one, this.notation = const CompactNotation.decimal(), this.prefix = '', this.suffix = '', this.prefixLabel, this.suffixLabel, this.separator = '', this.formatter});

  CompactInterval _withBounds(CompactPower from, CompactPower to) =>
      CompactInterval(from: from, to: to, scale: scale, notation: notation, prefix: prefix, suffix: suffix, prefixLabel: prefixLabel, suffixLabel: suffixLabel, separator: separator, formatter: formatter);

  @override
  bool operator ==(Object other) =>
      other is CompactInterval &&
      from == other.from &&
      to == other.to &&
      scale == other.scale &&
      notation == other.notation &&
      prefix == other.prefix &&
      suffix == other.suffix &&
      prefixLabel == other.prefixLabel &&
      suffixLabel == other.suffixLabel &&
      separator == other.separator &&
      formatter == other.formatter;
  @override
  int get hashCode => Object.hash(from, to, scale, notation, prefix, suffix, prefixLabel, suffixLabel, separator, formatter);
}

/// One finite formatting request. Exact decimal values are always available.
@immutable
class CompactFormattingContext {
  /// Original supported input type, retained for existing callbacks.
  final Object input;
  final _DecimalDigits _exactInput;
  final _DecimalDigits _exactValue;
  final String locale;
  final CompactFormatOptions options;
  final CompactInterval? interval;
  final String? _numberText;
  const CompactFormattingContext._({required this.input, required this._exactInput, required this._exactValue, required this.locale, required this.options, this.interval, this._numberText});

  Decimal get decimalInput => _exactInput.decimal;
  Decimal get decimalValue => _exactValue.decimal;

  /// Original value at a definition; rounded coefficient at an interval.
  /// num callers retain a num when representable, with Decimal for overflow.
  /// Decimal and BigInt callers receive Decimal. Use decimalValue for exact work.
  Object get value {
    if (interval == null) return input;
    if (input is num) {
      final legacy = num.tryParse('${_exactValue.coefficient}e${_exactValue.exponent}');
      if (legacy != null && legacy.isFinite && (legacy != 0 || _exactValue.isZero)) return legacy;
    }
    return decimalValue;
  }

  String formatDecimal(Object number) =>
      _specialNumber(number, locale, options) ?? _prepare(_DecimalDigits.from(number), const CompactNotation.decimal(), CompactPower.one, locale, options, defaultPrecision: interval == null ? const CompactPrecision.fraction(maximum: 3) : null).text;
  String formatCompact(Object number) => _specialNumber(number, locale, options) ?? _formatLocaleCompact(_DecimalDigits.from(number), locale, options);
  String formatSubscript(Object number) => formatNotation(number, const CompactNotation.zeroCount(sides: ZeroCountSides.leading));
  String formatNotation(Object number, CompactNotation notation) => _specialNumber(number, locale, options) ?? _prepare(_DecimalDigits.from(number), notation, CompactPower.one, locale, options).text;
  String get numberText => _numberText ?? formatDecimal(decimalValue);
  String get _fallbackText => options.fallbackFormatter(this) ?? defaultFallbackFormatter(this);
  String get defaultText {
    final selected = interval;
    if (selected == null) return numberText;
    String label(CompactLabel? key, String fallback) => key == null ? fallback : options.locale!.resolve(key, fallback: fallback);
    final prefix = label(selected.prefixLabel, selected.prefix);
    final suffix = label(selected.suffixLabel, selected.suffix);
    return '${prefix.isEmpty ? '' : '$prefix${selected.separator}'}$numberText${suffix.isEmpty ? '' : '${selected.separator}$suffix'}';
  }
}

/// Local intervals, then formatter, notation, base and ordinary localized decimals.
/// Rounding can promote to a higher local interval. Gaps and exhausted overrides
/// use the fallback chain with the original input. Callback text is never parsed.
@immutable
class CompactFormatDefinition {
  final CompactFormatDefinition? base;
  final List<CompactInterval> overrides;
  final CompactFormatter? formatter;
  final CompactNotation? notation;

  /// Opt in to formatting zero through intervals/callbacks (e.g. 0 B).
  final bool formatZero;
  final List<_ResolvedInterval> _resolved;

  factory CompactFormatDefinition({CompactFormatDefinition? base, Iterable<CompactInterval> overrides = const [], CompactFormatter? formatter, CompactNotation? notation, bool? formatZero}) {
    final values = List<CompactInterval>.unmodifiable(overrides);
    notation?.validate();
    return CompactFormatDefinition._(base, values, formatter, notation, formatZero ?? base?.formatZero ?? false, _resolve(values));
  }
  const CompactFormatDefinition._(this.base, this.overrides, this.formatter, this.notation, this.formatZero, this._resolved);

  /// Merges overrides into this definition's local intervals, retaining its
  /// formatter, notation and base. Missing bounds use the nearest strictly earlier/later
  /// boundary in the original target, or infinity when no boundary exists.
  /// Each override needs at least one bound. Overrides may arrive in any order
  /// but must not overlap each other. Covered target intervals are trimmed,
  /// split or replaced; all resulting bounds are explicit.
  CompactFormatDefinition copyWith({Iterable<CompactInterval>? overrides}) {
    if (overrides == null) return this;
    final boundaries = {
      for (final range in _resolved) ...[range.from, range.to],
    }.where((bound) => bound.isFinite).toList()..sort();
    final replacements = <CompactInterval>[];
    for (final interval in overrides) {
      var from = interval.from;
      var to = interval.to;
      if (from == null && to == null) throw ArgumentError('Each merging override must define at least one endpoint.');
      _validateBound(from, lower: true);
      _validateBound(to, lower: false);
      from ??= boundaries.where((bound) => bound < to!).lastOrNull ?? CompactPower.negativeInfinity;
      to ??= boundaries.where((bound) => bound > from!).firstOrNull ?? CompactPower.positiveInfinity;
      replacements.add(interval._withBounds(from, to));
    }
    if (replacements.isEmpty) return this;
    replacements.sort((a, b) => a.from!.compareTo(b.from!));
    final resolvedReplacements = _resolve(replacements);
    var merged = _resolved;
    for (final replacement in resolvedReplacements) {
      final next = <CompactInterval>[];
      for (final range in merged) {
        if (range.to <= replacement.from || range.from >= replacement.to) {
          next.add(range.interval._withBounds(range.from, range.to));
        } else {
          if (range.from < replacement.from) next.add(range.interval._withBounds(range.from, replacement.from));
          if (range.to > replacement.to) next.add(range.interval._withBounds(replacement.to, range.to));
        }
      }
      next.add(replacement.interval);
      next.sort((a, b) => a.from!.compareTo(b.from!));
      merged = _resolve(next);
    }
    return CompactFormatDefinition(base: base, formatter: formatter, notation: notation, formatZero: formatZero, overrides: merged.map((range) => range.interval));
  }

  String _format(CompactFormattingContext context) {
    var magnitude = context._exactInput;
    for (final range in _resolved) {
      if (range.lower != null && magnitude.compareMagnitude(range.lower!) < 0) break;
      if (range.upper != null && magnitude.compareMagnitude(range.upper!) >= 0) continue;
      final prepared = _prepare(context._exactInput, range.interval.notation, range.interval.scale, context.locale, context.options);
      if (range.upper != null && prepared.magnitude.compareMagnitude(range.upper!) >= 0) {
        magnitude = prepared.magnitude;
        continue;
      }
      final selected = CompactFormattingContext._(input: context.input, exactInput: context._exactInput, exactValue: prepared.rounded, locale: context.locale, options: context.options, interval: range.interval, numberText: prepared.text);
      return range.interval.formatter?.call(selected) ?? selected.defaultText;
    }
    return formatter?.call(context) ?? (notation == null ? null : _prepare(context._exactInput, notation!, CompactPower.one, context.locale, context.options).text) ?? base?._format(context) ?? context._fallbackText;
  }
}

class _ResolvedInterval {
  final CompactInterval interval;
  final CompactPower from, to;
  final _DecimalDigits? lower, upper;
  _ResolvedInterval(this.interval, CompactPower? from, CompactPower? to)
    : from = from ?? CompactPower.negativeInfinity,
      to = to ?? CompactPower.positiveInfinity,
      lower = from?.isFinite == true ? from!._decimal() : null,
      upper = to?.isFinite == true ? to!._decimal() : null;
}

void _validateBound(CompactPower? value, {required bool lower}) {
  if (value == null) return;
  value._factors();
  if (!value.isFinite && value.power != (lower ? double.negativeInfinity : double.infinity)) throw ArgumentError('Infinite bound is at the wrong end of the interval.');
}

List<_ResolvedInterval> _resolve(List<CompactInterval> intervals) {
  final resolved = <_ResolvedInterval>[];
  for (var i = 0; i < intervals.length; i++) {
    final interval = intervals[i];
    final from = interval.from ?? (i == 0 ? null : intervals[i - 1].to);
    final to = interval.to ?? (i == intervals.length - 1 ? null : intervals[i + 1].from);
    if (i > 0 && from == null || i < intervals.length - 1 && to == null) throw ArgumentError('Adjacent intervals must declare at least one endpoint of their shared boundary.');
    _validateBound(from, lower: true);
    _validateBound(to, lower: false);
    interval.notation.validate();
    interval.scale._decimal();
    if (interval.notation.isExponential && interval.scale.compareTo(CompactPower.one) != 0) throw ArgumentError('Exponential notation owns its scale; scale must be one.');
    final range = _ResolvedInterval(interval, from, to);
    if (range.from >= range.to || resolved.isNotEmpty && range.from < resolved.last.to) throw ArgumentError('Intervals must be ordered, nonempty and nonoverlapping.');
    resolved.add(range);
  }
  return List.unmodifiable(resolved);
}

/// Requested canonical locale, supported parent(s), then English.
String _resolveCompactLocale(Locale locale) {
  var candidate = Intl.canonicalizedLocale(locale.toString());
  while (true) {
    if (NumberFormat.localeExists(candidate)) return candidate;
    final separator = candidate.lastIndexOf('_');
    if (separator < 0) return 'en';
    candidate = candidate.substring(0, separator);
  }
}
