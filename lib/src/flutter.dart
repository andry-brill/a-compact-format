import 'package:flutter/widgets.dart';

import 'formatter.dart' as core;
import 'options.dart';

/// Nested providers inherit options and replace an explicit locale as a whole.
/// A root provider defaults to English.
class CompactFormatProvider extends StatelessWidget {
  final CompactFormatOptions? options;
  final Widget child;
  const CompactFormatProvider({super.key, this.options, required this.child});
  static CompactFormatOptions? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_Scope>()?.options;
  static CompactFormatOptions of(BuildContext context) => maybeOf(context) ?? (throw FlutterError('No CompactFormatProvider found. Supply options with a locale or add a provider.'));
  @override
  Widget build(BuildContext context) {
    final resolved = (maybeOf(context) ?? CompactFormatOptions.defaults).merge(options);
    return _Scope(options: resolved, child: child);
  }
}

class _Scope extends InheritedWidget {
  final CompactFormatOptions options;
  const _Scope({required this.options, required super.child});
  @override
  bool updateShouldNotify(_Scope oldWidget) => options != oldWidget.options;
}

extension CompactFormatContext on BuildContext {
  String compactFormat(Object value, {CompactFormatOptions? options}) => core.compactFormat(value, options: (CompactFormatProvider.maybeOf(this) ?? CompactFormatOptions.defaults).merge(options));
}

/// Ordinary Text presentation, with no currency labels, fitting or tooltips.
class CompactFormatText extends StatelessWidget {
  final Object value;
  final CompactFormatOptions? options;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  const CompactFormatText(
    this.value, {
    super.key,
    this.options,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });
  @override
  Widget build(BuildContext context) => Text(
    context.compactFormat(value, options: options),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
  );
}
