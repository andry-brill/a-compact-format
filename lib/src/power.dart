part of 'formatter.dart';

/// An exact positive magnitude, base^power. Bases contain only factors 2 and 5
/// so both multiplication and division have finite decimal representations.
/// Infinite powers explicitly open a bound; omitted bounds still infer.
@immutable
final class CompactPower implements Comparable<CompactPower> {
  final int base;
  final num power;
  const CompactPower({this.base = 10, required this.power});

  static const negativeInfinity = CompactPower(power: double.negativeInfinity);
  static const positiveInfinity = CompactPower(power: double.infinity);
  static const one = CompactPower(power: 0);

  bool get isFinite => power.isFinite;

  (int, int) _factors() {
    if (base < 2 || base > 1000000000) throw ArgumentError.value(base, 'base', 'Expected 2..1000000000.');
    var remaining = base;
    var twos = 0;
    var fives = 0;
    while (remaining % 2 == 0) {
      twos++;
      remaining ~/= 2;
    }
    while (remaining % 5 == 0) {
      fives++;
      remaining ~/= 5;
    }
    if (remaining != 1) throw ArgumentError.value(base, 'base', 'Only factors 2 and 5 are supported for exact decimal scaling.');
    if (power.isNaN || isFinite && (power != power.truncateToDouble() || power.abs() * math.max(twos, fives) > 100000)) {
      throw ArgumentError.value(power, 'power', 'Expected an integer power with at most 100000 factors of either 2 or 5, or an infinite bound.');
    }
    return (twos, fives);
  }

  _DecimalDigits _decimal({bool reciprocal = false}) {
    final (twos, fives) = _factors();
    if (!isFinite) throw ArgumentError('An infinite CompactPower cannot be used as a scale.');
    final exponent = power.toInt() * (reciprocal ? -1 : 1);
    final twoPower = twos * exponent;
    final fivePower = fives * exponent;
    final common = math.min(twoPower, fivePower);
    return _DecimalDigits._(BigInt.two.pow(twoPower - common) * BigInt.from(5).pow(fivePower - common), common);
  }

  @override
  int compareTo(CompactPower other) {
    _factors();
    other._factors();
    if (!isFinite || !other.isFinite) {
      if (power == other.power && !isFinite && !other.isFinite) return 0;
      if (power == double.negativeInfinity || other.power == double.infinity) return -1;
      return 1;
    }
    return _decimal().compareMagnitude(other._decimal());
  }

  bool operator <(CompactPower other) => compareTo(other) < 0;
  bool operator <=(CompactPower other) => compareTo(other) <= 0;
  bool operator >(CompactPower other) => compareTo(other) > 0;
  bool operator >=(CompactPower other) => compareTo(other) >= 0;

  // Structural equality preserves the authored representation. compareTo uses
  // magnitude, so 2^10 and 1024^1 compare equally even though they differ here.
  @override
  bool operator ==(Object other) => other is CompactPower && base == other.base && power == other.power;
  @override
  int get hashCode => Object.hash(base, power);
}
