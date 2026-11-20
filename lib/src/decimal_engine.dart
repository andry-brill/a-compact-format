part of 'formatter.dart';

String? _specialNumber(Object value, String locale, CompactFormatOptions options) {
  if (value is! num || value.isFinite) return null;
  final formatter = NumberFormat.decimalPattern(locale);
  final sign = options.explicitSign == true && value >= 0 ? formatter.symbols.PLUS_SIGN : '';
  return '$sign${formatter.format(value)}';
}

/// Exact signed coefficient times a power of ten. No binary scaling or rounding.
final class _DecimalDigits {
  final BigInt coefficient;
  final int exponent;
  const _DecimalDigits._(this.coefficient, this.exponent);

  factory _DecimalDigits(BigInt coefficient, int exponent) {
    if (coefficient == BigInt.zero) return _DecimalDigits._(BigInt.zero, 0);
    while (coefficient.remainder(BigInt.from(10)) == BigInt.zero) {
      coefficient ~/= BigInt.from(10);
      exponent++;
    }
    return _DecimalDigits._(coefficient, exponent);
  }

  factory _DecimalDigits.from(Object value) {
    if (value is BigInt) return _DecimalDigits(value, 0);
    if (value is! Decimal && value is! num) throw ArgumentError.value(value, 'value', 'Expected num, Decimal or BigInt.');
    if (value is num && !value.isFinite) throw ArgumentError.value(value, 'value', 'Expected a finite value.');
    final parts = value.toString().toLowerCase().split('e');
    final decimal = parts.first.split('.');
    return _DecimalDigits(BigInt.parse(decimal.join()), (parts.length == 1 ? 0 : int.parse(parts.last)) - (decimal.length == 1 ? 0 : decimal.last.length));
  }

  bool get isZero => coefficient == BigInt.zero;
  bool get isNegative => coefficient.isNegative;
  String get digits => coefficient.abs().toString();
  int get order => isZero ? 0 : digits.length - 1 + exponent;
  Decimal get decimal => Decimal.parse('${coefficient}e$exponent');
  _DecimalDigits multiply(_DecimalDigits other) => _DecimalDigits(coefficient * other.coefficient, exponent + other.exponent);

  int compareMagnitude(_DecimalDigits other) {
    if (isZero || other.isZero) return (isZero ? 0 : 1).compareTo(other.isZero ? 0 : 1);
    if (order != other.order) return order.compareTo(other.order);
    final common = math.min(exponent, other.exponent);
    return (coefficient.abs() * BigInt.from(10).pow(exponent - common)).compareTo(other.coefficient.abs() * BigInt.from(10).pow(other.exponent - common));
  }

  _DecimalDigits round(CompactPrecision precision, CompactRounding mode) {
    precision.validate();
    if (isZero) return this;
    final target = precision.isSignificant ? order - precision.maximum + 1 : -precision.maximum;
    if (target <= exponent) return this;
    final divisor = BigInt.from(10).pow(target - exponent);
    final magnitude = coefficient.abs();
    var quotient = magnitude ~/ divisor;
    final remainder = magnitude.remainder(divisor);
    final comparison = (remainder * BigInt.two).compareTo(divisor);
    final increment = switch (mode) {
      CompactRounding.towardZero => false,
      CompactRounding.floor => isNegative && remainder != BigInt.zero,
      CompactRounding.ceil => !isNegative && remainder != BigInt.zero,
      CompactRounding.halfAwayFromZero => comparison >= 0,
      CompactRounding.halfEven => comparison > 0 || comparison == 0 && quotient.isOdd,
    };
    if (increment) quotient += BigInt.one;
    return _DecimalDigits(isNegative ? -quotient : quotient, target);
  }

  String ascii(CompactPrecision precision) {
    final position = digits.length + exponent;
    final String whole;
    var fraction = '';
    if (position <= 0) {
      whole = '0';
      fraction = '${'0' * -position}$digits';
    } else if (position >= digits.length) {
      whole = digits.padRight(position, '0');
    } else {
      whole = digits.substring(0, position);
      fraction = digits.substring(position);
    }
    final minimumFraction = precision.isSignificant ? math.max(0, precision.minimum - (isZero ? 1 : order + 1)) : precision.minimum;
    fraction = fraction.padRight(minimumFraction, '0');
    return '$whole${fraction.isEmpty ? '' : '.$fraction'}';
  }
}

final class _PreparedNumber {
  final _DecimalDigits rounded;
  final CompactPower scale;
  final String text;
  const _PreparedNumber(this.rounded, this.scale, this.text);
  _DecimalDigits get magnitude => rounded.multiply(scale._decimal());
}

_PreparedNumber _prepare(_DecimalDigits original, CompactNotation notation, CompactPower fixedScale, String locale, CompactFormatOptions options, {CompactPrecision? defaultPrecision}) {
  notation.validate();
  final precision = options.precision ?? defaultPrecision ?? const CompactPrecision.significant(maximum: 3);
  final mode = options.rounding ?? CompactRounding.halfAwayFromZero;
  int scaleFor(int order) => notation.isEngineering ? order - order % 3 : order;
  var scale = notation.isExponential && !original.isZero ? CompactPower(power: scaleFor(original.order)) : fixedScale;
  var rounded = original.multiply(scale._decimal(reciprocal: true)).round(precision, mode);
  if (notation.isExponential && !rounded.isZero) {
    final corrected = scaleFor(rounded.order + scale.power.toInt());
    if (corrected != scale.power) {
      scale = CompactPower(power: corrected);
      rounded = original.multiply(scale._decimal(reciprocal: true)).round(precision, mode);
    }
  }
  var ascii = rounded.ascii(precision);
  if (notation.compressesZeros && !rounded.isZero) ascii = _compressZeros(ascii, notation);
  var text = _localizeDecimal(ascii, rounded.isNegative, locale, options.explicitSign ?? false);
  if (notation.isExponential && !rounded.isZero) text = '$text × 10${_script('${scale.power.toInt()}', CompactScript.superscript)}';
  return _PreparedNumber(rounded, scale, text);
}

String _script(String text, CompactScript script) {
  final digits = script == CompactScript.subscript ? '₀₁₂₃₄₅₆₇₈₉' : '⁰¹²³⁴⁵⁶⁷⁸⁹';
  return text.split('').map((char) => char == '-' ? (script == CompactScript.subscript ? '₋' : '⁻') : digits[int.parse(char)]).join();
}

String _compressZeros(String ascii, CompactNotation notation) {
  if (notation.sides != ZeroCountSides.trailing && ascii.startsWith('0.')) {
    final fraction = ascii.substring(2);
    final count = RegExp(r'^0+(?=[1-9])').firstMatch(fraction)?.end ?? 0;
    if (count >= notation.minimumZeros) return '0.0${_script('$count', notation.script)}${fraction.substring(count)}';
  }
  // A decimal suffix can encode required precision; never compress its padding.
  if (notation.sides != ZeroCountSides.leading && !ascii.contains('.')) {
    final run = RegExp(r'0+$').firstMatch(ascii);
    if (run != null && ascii.length - run.start >= notation.minimumZeros) {
      // Both visible zeros mark one run; the count includes every trailing zero.
      // 213000000 -> 2130₆0, with no additional zero implied by the final marker.
      final count = ascii.length - run.start;
      return '${ascii.substring(0, run.start)}0${_script('$count', notation.script)}0';
    }
  }
  return ascii;
}

String _localizeDecimal(String ascii, bool negative, String locale, bool explicitSign) {
  final formatter = NumberFormat.decimalPattern(locale);
  final zero = formatter.symbols.ZERO_DIGIT.runes.single;
  final localized = String.fromCharCodes(ascii.runes.expand((code) => code == 46 ? formatter.symbols.DECIMAL_SEP.runes : [code >= 48 && code <= 57 ? zero + code - 48 : code]));
  final prefix = negative ? formatter.negativePrefix : '${explicitSign ? formatter.symbols.PLUS_SIGN : ''}${formatter.positivePrefix}';
  return '$prefix$localized${negative ? formatter.negativeSuffix : formatter.positiveSuffix}';
}

/// Locale compact patterns from intl, with the same exact numeric engine.
String _formatLocaleCompact(_DecimalDigits original, String locale, CompactFormatOptions options) {
  var symbolLocale = locale;
  while (!compactNumberSymbols.containsKey(symbolLocale)) {
    final separator = symbolLocale.lastIndexOf('_');
    symbolLocale = separator < 0 ? 'en' : symbolLocale.substring(0, separator);
  }
  final patterns = compactNumberSymbols[symbolLocale]!.COMPACT_DECIMAL_SHORT_PATTERN;
  final exponents = patterns.keys.toList()..sort();
  var order = original.order;
  while (true) {
    final exponent = exponents.where((key) => key <= order).lastOrNull;
    if (exponent == null) {
      final result = _prepare(original, const CompactNotation.decimal(), CompactPower.one, locale, options);
      if (!result.magnitude.isZero && exponents.isNotEmpty && result.magnitude.order >= exponents.first) {
        order = result.magnitude.order;
        continue;
      }
      return result.text;
    }
    final variants = patterns[exponent]!;
    final pattern = variants['other']!;
    final zeroRun = RegExp('0+').firstMatch(pattern);
    final scale = RegExp(r'^0+$').hasMatch(pattern) || zeroRun == null ? 0 : exponent - zeroRun.group(0)!.length + 1;
    final result = _prepare(original, const CompactNotation.decimal(), CompactPower(power: scale), locale, options);
    final next = exponents.where((key) => key > exponent).firstOrNull;
    if (next != null && !result.magnitude.isZero && result.magnitude.order >= next) {
      order = result.magnitude.order;
      continue;
    }
    final precision = options.precision ?? const CompactPrecision.significant(maximum: 3);
    final ascii = result.rounded.ascii(precision);
    // intl's plural operands use fixed-width arithmetic. Use its generic form
    // beyond safe operand precision/range; numeric rendering stays exact.
    final pluralValue = num.tryParse('${result.rounded.coefficient}e${result.rounded.exponent}');
    final fractionDigits = ascii.contains('.') ? ascii.split('.').last.length : 0;
    final safePlural = fractionDigits <= 15 && pluralValue != null && pluralValue.isFinite && pluralValue.abs() * math.pow(10, fractionDigits) <= 9007199254740991;
    final category = !safePlural ? 'other' : Intl.pluralLogic(pluralValue.abs(), locale: locale, precision: fractionDigits, useExplicitNumberCases: false, zero: 'zero', one: 'one', two: 'two', few: 'few', many: 'many', other: 'other');
    final selected = (!result.rounded.isNegative ? variants[ascii] : null) ?? variants[category] ?? (category == 'two' ? variants['few'] : null) ?? pattern;
    if (!selected.contains('0')) {
      final sign = _localizeDecimal('', result.rounded.isNegative, locale, options.explicitSign ?? false);
      return '$sign${selected.replaceAll("'", '')}';
    }
    // Compact patterns treat punctuation in affixes literally (e.g. nb 'mill.');
    // a decimal-pattern parser would consume that dot as a decimal separator.
    final signedPatterns = selected.split(';');
    final explicitNegative = result.rounded.isNegative && signedPatterns.length > 1;
    final selectedPattern = explicitNegative ? signedPatterns[1] : signedPatterns.first;
    final match = RegExp(r'([^0]*)(0+)(.*)').firstMatch(selectedPattern)!;
    final sign = explicitNegative ? '' : _localizeDecimal('', result.rounded.isNegative, locale, options.explicitSign ?? false);
    return '$sign${match.group(1)}${_localizeDecimal(ascii, false, locale, false)}${match.group(3)}';
  }
}
