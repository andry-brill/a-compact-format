import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binary = CompactFormatOptions(locale: english.locale, format: fileSizeBinary, precision: const CompactPrecision.fraction(maximum: 2));
  final decimal = binary.copyWith(format: fileSizeDecimal);

  test('binary and decimal byte units share precision, signs and exact inputs', () {
    for (final sample in <String, (String, String)>{
      '0': ('0 B', '0 B'),
      '0.125': ('0.13 B', '0.13 B'),
      '999': ('999 B', '999 B'),
      '1000': ('1000 B', '1 kB'),
      '1023': ('1023 B', '1.02 kB'),
      '1024': ('1 KiB', '1.02 kB'),
      '1500': ('1.46 KiB', '1.5 kB'),
      '1536': ('1.5 KiB', '1.54 kB'),
      '1048576': ('1 MiB', '1.05 MB'),
    }.entries) {
      final value = Decimal.parse(sample.key);
      expect(compactFormat(value, options: binary), sample.value.$1);
      expect(compactFormat(value, options: decimal), sample.value.$2);
      if (value != Decimal.zero) {
        expect(compactFormat(-value, options: binary), '-${sample.value.$1}');
        expect(compactFormat(-value, options: decimal), '-${sample.value.$2}');
      }
    }
    expect(compactFormat(1536, options: binary.copyWith(precision: const CompactPrecision.significant(minimum: 3, maximum: 3))), '1.50 KiB');
    expect(
      compactFormat(
        1536,
        options: binary.copyWith(locale: english.locale.copyWith(locale: Locale('nb')), explicitSign: true),
      ),
      '+1,5 KiB',
    );
    expect(
      compactFormat(
        -1536,
        options: binary.copyWith(locale: english.locale.copyWith(locale: Locale('nb'))),
      ),
      '−1,5 KiB',
    );
    expect(compactFormat(-0.0, options: binary.copyWith(explicitSign: true, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))), '+0.00 B');
  });

  test('every unit threshold is exact and larger amounts retain the last unit', () {
    for (final entry in [
      (1024, ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'], binary),
      (1000, ['B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB', 'RB', 'QB'], decimal),
    ]) {
      for (var index = 0; index < entry.$2.length; index++) {
        final amount = BigInt.from(entry.$1).pow(index);
        expect(compactFormat(amount, options: entry.$3), '1 ${entry.$2[index]}');
        expect(compactFormat(-amount, options: entry.$3), '-1 ${entry.$2[index]}');
      }
      expect(compactFormat(BigInt.from(entry.$1).pow(entry.$2.length), options: entry.$3), '${entry.$1} ${entry.$2.last}');
    }
    expect(compactFormat(BigInt.from(2).pow(400), options: binary), '${BigInt.from(2).pow(320)} YiB');
    expect(compactFormat(Decimal.parse('1e-400'), options: binary.copyWith(precision: const CompactPrecision.significant(maximum: 3))), '0.${'0' * 399}1 B');
  });

  test('rounding promotes at exact binary and decimal bounds using original input', () {
    expect(compactFormat(1023.999, options: binary), '1 KiB');
    expect(compactFormat(1048575, options: binary), '1 MiB');
    expect(compactFormat(-1048575, options: binary), '-1 MiB');
    expect(compactFormat(999999, options: decimal), '1 MB');
    expect(compactFormat(1048575, options: binary.copyWith(rounding: CompactRounding.towardZero)), '1023.99 KiB');
    expect(compactFormat(-1048575, options: binary.copyWith(rounding: CompactRounding.ceil)), '-1023.99 KiB');
    expect(compactFormat(-1048575, options: binary.copyWith(rounding: CompactRounding.floor)), '-1 MiB');
    expect(
      compactFormat(
        1280,
        options: binary.copyWith(precision: const CompactPrecision.fraction(maximum: 1), rounding: CompactRounding.halfEven),
      ),
      '1.2 KiB',
    );
    expect(compactFormat(1280, options: binary.copyWith(precision: const CompactPrecision.fraction(maximum: 1))), '1.3 KiB');
    expect(compactFormat(Decimal.parse('1023.999999999999999999999'), options: binary.copyWith(precision: const CompactPrecision.fraction(maximum: 25))), '1023.999999999999999999999 B');
  });

  test('file-size overrides retain zero units and final callbacks after promotion', () {
    var calls = 0;
    final custom = fileSizeBinary.copyWith(
      overrides: [
        CompactInterval(
          from: const CompactPower(base: 1024, power: 2),
          scale: const CompactPower(base: 1024, power: 2),
          suffix: ' mebibytes',
          formatter: (context) {
            calls++;
            expect(context.decimalInput, Decimal.fromInt(1048575));
            expect(context.decimalValue, Decimal.one);
            return null;
          },
        ),
      ],
    );
    expect(compactFormat(1048575, options: binary.copyWith(format: custom)), '1 mebibytes');
    expect(calls, 1);
    expect(compactFormat(0, options: binary.copyWith(format: custom)), '0 B');
    expect(
      compactFormat(
        0,
        options: binary.copyWith(format: CompactFormatDefinition(base: fileSizeBinary)),
      ),
      '0 B',
    );
    expect(compactFormat(0, options: binary.copyWith(format: narrowNatural)), '0');
  });

  testWidgets('provider and text accept BigInt byte counts', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CompactFormatProvider(options: binary, child: CompactFormatText(BigInt.from(1024).pow(3))),
      ),
    );
    expect(find.text('1 GiB'), findsOneWidget);
  });
}
