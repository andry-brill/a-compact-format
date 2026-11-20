import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = CompactFormatOptions(locale: english.locale, format: subscriptCompact);

  test('subscript counts leading zeros, including extreme finite doubles', () {
    for (final entry in <double, String>{0.1: '0.1', 0.001234: '0.00123', 0.0001: '0.0001', 0.00001: '0.0₄1', 0.000001234: '0.0₅123', 1e-11: '0.0₁₀1', 1e-36: '0.0₃₅1', 1e-100: '0.0₉₉1', 1e-308: '0.0₃₀₇1', double.minPositive: '0.0₃₂₃5'}.entries) {
      expect(compactFormat(entry.key, options: options), entry.value, reason: '${entry.key}');
      expect(compactFormat(-entry.key, options: options), '-${entry.value}', reason: '-${entry.key}');
    }
  });

  test('rounding updates zero counts and can leave subscript notation', () {
    expect(compactFormat(0.000009999, options: options), '0.0₄1');
    expect(compactFormat(0.00009999, options: options), '0.0001');
    expect(compactFormat(-0.00009999, options: options), '-0.0001');
    expect(compactFormat(0.9999, options: options), '1');
    expect(compactFormat(0.000001234567, options: options.copyWith(precision: const CompactPrecision.significant(maximum: 4))), '0.0₅1235');
    expect(compactFormat(1e-36, options: options.copyWith(precision: const CompactPrecision.significant(minimum: 4, maximum: 4))), '0.0₃₅1000');
    expect(compactFormat(0.0000012, options: options.copyWith(precision: const CompactPrecision.fraction(minimum: 8, maximum: 8))), '0.0₅120');
    expect(compactFormat(-1e-36, options: options.copyWith(precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))), '0.00');
    expect(() => compactFormat(1e-36, options: options.copyWith(precision: const CompactPrecision.significant(maximum: 0))), throwsArgumentError);
  });

  test('ordinary digits, decimal separators and signs stay localized', () {
    expect(
      compactFormat(
        1e-36,
        options: options.copyWith(locale: english.locale.copyWith(locale: Locale('nb'))),
      ),
      '0,0₃₅1',
    );
    expect(
      compactFormat(
        -1e-36,
        options: options.copyWith(locale: english.locale.copyWith(locale: Locale('nb'))),
      ),
      '−0,0₃₅1',
    );
    expect(
      compactFormat(
        1e-36,
        options: options.copyWith(locale: english.locale.copyWith(locale: Locale('nb')), explicitSign: true),
      ),
      '+0,0₃₅1',
    );
    expect(
      compactFormat(
        0.000001234,
        options: options.copyWith(locale: english.locale.copyWith(locale: Locale('fa'))),
      ),
      '۰٫۰₅۱۲۳',
    );
    expect(
      compactFormat(
        1e-36,
        options: options.copyWith(locale: english.locale.copyWith(locale: Locale('zz', 'ZZ'))),
      ),
      '0.0₃₅1',
    );
  });

  test('large values delegate and zero and special values keep existing behavior', () {
    for (final locale in [const Locale('en'), const Locale('nb'), const Locale('fa')]) {
      for (final sign in [false, true]) {
        final localized = options.copyWith(
          locale: english.locale.copyWith(locale: locale),
          explicitSign: sign,
        );
        for (final value in [0, -0.0, 1, -1, 1234, 1234567, -1234567, double.nan, double.infinity, double.negativeInfinity]) {
          expect(
            compactFormat(value, options: localized),
            compactFormat(value, options: localized.copyWith(format: localizedCompact)),
            reason: '$locale: $value',
          );
        }
      }
    }
    expect(compactFormat(1e-6, options: options.copyWith(format: narrowCompact)), '1µ');
  });

  test('reusable override replaces every narrow subunit interval and retains larger ones', () {
    final custom = narrowCompact.copyWith(overrides: subscriptOverrides);
    expect(compactFormat(1e-36, options: options.copyWith(format: custom)), '0.0₃₅1');
    expect(compactFormat(1e-30, options: options.copyWith(format: custom)), '0.0₂₉1');
    expect(compactFormat(1e-6, options: options.copyWith(format: custom)), '0.0₅1');
    expect(compactFormat(1e-3, options: options.copyWith(format: custom)), '0.001');
    expect(compactFormat(0.9999, options: options.copyWith(format: custom)), '1');
    expect(compactFormat(1200, options: options.copyWith(format: custom)), '1.2k');
    expect(custom.overrides.first.from, CompactPower.negativeInfinity);
    expect(custom.overrides.first.to, CompactPower.one);
    expect(
      custom.overrides.skip(1),
      narrowCompact.overrides
          .where((interval) => interval.from! >= CompactPower.one)
          .map(
            (interval) => CompactInterval(
              from: interval.from,
              to: interval.to ?? CompactPower(base: interval.from!.base, power: interval.from!.power + 3),
              scale: interval.scale,
              suffix: interval.suffix,
              suffixLabel: interval.suffixLabel,
            ),
          ),
    );
    expect(() => subscriptOverrides.clear(), throwsUnsupportedError);
    expect(compactFormat(1e-6, options: options.copyWith(format: narrowCompact)), '1µ');
  });

  test('subscript override composes with custom large units and all count digits', () {
    final custom = narrowCompact
        .copyWith(
          overrides: [const CompactInterval(from: CompactPower(power: 6), scale: CompactPower(power: 6), suffix: ' million')],
        )
        .copyWith(overrides: subscriptOverrides);
    expect(compactFormat(1234567, options: options.copyWith(format: custom)), '1.23 million');
    for (var digit = 0; digit < 10; digit++) {
      final value = double.parse('1e-${11 + digit}');
      expect(compactFormat(value, options: options.copyWith(format: custom)), '0.0₁${'₀₁₂₃₄₅₆₇₈₉'[digit]}1');
    }
  });

  testWidgets('provider renders plain subscript text with an accessible label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CompactFormatProvider(
          options: options.copyWith(locale: english.locale.copyWith(locale: Locale('nb'))),
          child: const CompactFormatText(1e-36, semanticsLabel: 'Ten to the power of minus thirty-six'),
        ),
      ),
    );
    expect(find.text('0,0₃₅1'), findsOneWidget);
    expect(find.bySemanticsLabel('Ten to the power of minus thirty-six'), findsOneWidget);
    semantics.dispose();
  });
}
