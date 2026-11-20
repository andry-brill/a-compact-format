import 'package:flutter/foundation.dart';

enum CompactScript { subscript, superscript }

enum ZeroCountSides { leading, trailing, both }

enum _NotationKind { decimal, zeroCount, scientific, engineering }

/// A numeric notation chooses its scale before rounding, then renders the result.
@immutable
class CompactNotation {
  final _NotationKind _kind;
  final CompactScript script;
  final ZeroCountSides sides;
  final int minimumZeros;
  const CompactNotation.decimal() : _kind = _NotationKind.decimal, script = CompactScript.subscript, sides = ZeroCountSides.both, minimumZeros = 4;
  const CompactNotation.zeroCount({this.script = CompactScript.subscript, this.sides = ZeroCountSides.both, this.minimumZeros = 4}) : _kind = _NotationKind.zeroCount;
  const CompactNotation.scientific() : _kind = _NotationKind.scientific, script = CompactScript.superscript, sides = ZeroCountSides.both, minimumZeros = 4;
  const CompactNotation.engineering() : _kind = _NotationKind.engineering, script = CompactScript.superscript, sides = ZeroCountSides.both, minimumZeros = 4;

  bool get isExponential => _kind == _NotationKind.scientific || _kind == _NotationKind.engineering;
  bool get isEngineering => _kind == _NotationKind.engineering;
  bool get compressesZeros => _kind == _NotationKind.zeroCount;

  void validate() {
    if (minimumZeros < 2) throw ArgumentError.value(minimumZeros, 'minimumZeros', 'Must be at least two.');
  }

  @override
  bool operator ==(Object other) => other is CompactNotation && _kind == other._kind && script == other.script && sides == other.sides && minimumZeros == other.minimumZeros;
  @override
  int get hashCode => Object.hash(_kind, script, sides, minimumZeros);
}
