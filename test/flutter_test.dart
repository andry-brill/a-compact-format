import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as english;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = CompactFormatOptions(locale: english.locale);
  Widget host(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);
  testWidgets('explicit and omitted locales work without a provider', (tester) async {
    await tester.pumpWidget(host(CompactFormatText(1234, options: en)));
    expect(find.text('1.23K'), findsOneWidget);
    await tester.pumpWidget(host(const CompactFormatText(1234)));
    expect(tester.takeException(), isNull);
    expect(find.text('1.23K'), findsOneWidget);
    await tester.pumpWidget(host(const CompactFormatProvider(child: CompactFormatText(1))));
    expect(tester.takeException(), isNull);
    expect(find.text('1'), findsOneWidget);
  });
  testWidgets('nested options and explicit overrides agree across builders and text', (tester) async {
    await tester.pumpWidget(
      host(
        CompactFormatProvider(
          options: en.copyWith(format: narrowCompact, explicitSign: true),
          child: CompactFormatProvider(
            options: CompactFormatOptions(
              locale: english.locale.copyWith(locale: Locale('nb')),
              precision: CompactPrecision.fraction(minimum: 2, maximum: 2),
            ),
            child: Column(
              children: [
                const CompactFormatText(1200),
                Builder(
                  builder: (context) {
                    expect(CompactFormatProvider.of(context).format, same(narrowCompact));
                    return Text(context.compactFormat(1200));
                  },
                ),
                CompactFormatText(1200, options: CompactFormatOptions(locale: english.locale, explicitSign: false)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('+1,20k'), findsNWidgets(2));
    expect(find.text('1.20k'), findsOneWidget);
  });
  testWidgets('value, locale, definition and precision changes rebuild', (tester) async {
    var options = en.copyWith(format: narrowCompact);
    var value = 1200;
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return CompactFormatProvider(options: options, child: CompactFormatText(value));
          },
        ),
      ),
    );
    expect(find.text('1.2k'), findsOneWidget);
    update(() {
      value = 1234567;
      options = options.copyWith(
        locale: english.locale.copyWith(locale: Locale('nb')),
        precision: const CompactPrecision.significant(maximum: 2),
      );
    });
    await tester.pump();
    expect(find.text('1,2M'), findsOneWidget);
    update(() {
      options = options.copyWith(
        format: CompactFormatDefinition(
          base: narrowCompact,
          overrides: const [CompactInterval(from: CompactPower(power: 6), to: CompactPower(power: 9), scale: CompactPower(power: 6), suffix: 'million')],
        ),
      );
    });
    await tester.pump();
    expect(find.text('1,2million'), findsOneWidget);
    update(() {
      options = options.copyWith(format: localizedCompact);
    });
    await tester.pump();
    expect(find.text(compactFormat(value, options: options)), findsOneWidget);
  });
  testWidgets('child default replaces format without changing explicit format references', (tester) async {
    final custom = CompactFormatDefinition(
      base: narrowCompact,
      overrides: const [CompactInterval(from: CompactPower(power: 3), to: CompactPower(power: 6), scale: CompactPower(power: 3), suffix: 'thousand')],
    );
    await tester.pumpWidget(
      host(
        CompactFormatProvider(
          options: en.copyWith(format: narrowCompact),
          child: CompactFormatProvider(
            options: CompactFormatOptions(
              locale: english.locale.copyWith(locale: Locale('nb')),
              format: custom,
            ),
            child: Column(
              children: [
                const CompactFormatText(1200),
                CompactFormatText(1200, options: CompactFormatOptions(format: narrowCompact)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('1,2thousand'), findsOneWidget);
    expect(find.text('1,2k'), findsOneWidget);
  });
  testWidgets('text forwards styling and semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(CompactFormatText(1200, options: en, semanticsLabel: 'Twelve hundred', style: TextStyle(fontSize: 20), maxLines: 1)));
    expect(find.bySemanticsLabel('Twelve hundred'), findsOneWidget);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style!.fontSize, 20);
    expect(text.maxLines, 1);
    semantics.dispose();
  });
}
