import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/en.dart' as en;
import 'package:any_compact_format/locales/uk.dart' as uk;
import 'package:any_compact_format/locales/bg.dart' as bg;
import 'package:any_compact_format/locales/cs.dart' as cs;
import 'package:any_compact_format/locales/de.dart' as de;
import 'package:any_compact_format/locales/es.dart' as es;
import 'package:any_compact_format/locales/fr.dart' as fr;
import 'package:any_compact_format/locales/hi.dart' as hi;
import 'package:any_compact_format/locales/hu.dart' as hu;
import 'package:any_compact_format/locales/id.dart' as id;
import 'package:any_compact_format/locales/it.dart' as it;
import 'package:any_compact_format/locales/ja.dart' as ja;
import 'package:any_compact_format/locales/ko.dart' as ko;
import 'package:any_compact_format/locales/nl.dart' as nl;
import 'package:any_compact_format/locales/pl.dart' as pl;
import 'package:any_compact_format/locales/pt.dart' as pt;
import 'package:any_compact_format/locales/pt_pt.dart' as pt_pt;
import 'package:any_compact_format/locales/ro.dart' as ro;
import 'package:any_compact_format/locales/ru.dart' as ru;
import 'package:any_compact_format/locales/sk.dart' as sk;
import 'package:any_compact_format/locales/sv.dart' as sv;
import 'package:any_compact_format/locales/tr.dart' as tr;
import 'package:any_compact_format/locales/vi.dart' as vi;
import 'package:any_compact_format/locales/zh.dart' as zh;
import 'package:flutter/material.dart';

void main() => runApp(const CompactExampleApp());

/// The same examples in every cell; only locale and base format vary.
class CompactExampleApp extends StatelessWidget {
  const CompactExampleApp({super.key});

  @override
  Widget build(BuildContext context) => CompactFormatProvider(
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'Noto Sans',
      ),
      title: 'any_compact_format',
      home: Scaffold(
        appBar: AppBar(title: const Text('any_compact_format')),
        body: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('page-scroll'),
            child: Column(children: [const _FeatureShowcase(), const _LocaleComparison(), const _NotationComparison()]),
          ),
        ),
      ),
    ),
  );
}

/// The opening section is self-contained so it can be captured for the README.
class _FeatureShowcase extends StatelessWidget {
  const _FeatureShowcase();

  static final _samples = <({String feature, String preset, String input, Object value, CompactFormatOptions options})>[
    (feature: 'Compact numbers', preset: 'narrowNatural', input: '1 234 567', value: 1234567, options: CompactFormatOptions(format: narrowNatural)),
    (feature: 'Tiny decimals', preset: 'narrowNatural · Decimal', input: '0.000000000001234', value: Decimal.parse('0.000000000001234'), options: CompactFormatOptions(format: narrowNatural)),
    (feature: 'Huge integers', preset: 'narrowNatural · BigInt', input: '123 000 000 000 000 000', value: BigInt.parse('123000000000000000'), options: CompactFormatOptions(format: narrowNatural)),
    (feature: 'Scientific', preset: 'scientificCompact', input: '0.000000000001234', value: Decimal.parse('0.000000000001234'), options: CompactFormatOptions(format: scientificCompact)),
    (feature: 'Engineering', preset: 'engineeringCompact', input: '12 345 000', value: 12345000, options: CompactFormatOptions(format: engineeringCompact)),
    (feature: 'SI prefixes', preset: 'narrowCompact', input: '0.00000123', value: Decimal.parse('0.00000123'), options: CompactFormatOptions(format: narrowCompact)),
    (feature: 'Sign & precision', preset: 'Explicit sign · 2 fraction digits', input: '1 200', value: 1200, options: CompactFormatOptions(format: narrowNatural, explicitSign: true, precision: const CompactPrecision.fraction(minimum: 2, maximum: 2))),
    (feature: 'Localization', preset: 'narrowNatural · Ukrainian', input: '1 234', value: 1234, options: CompactFormatOptions(format: narrowNatural, locale: uk.locale)),
    (feature: 'File sizes', preset: 'fileSizeBinary', input: '1 536 bytes', value: 1536, options: CompactFormatOptions(format: fileSizeBinary)),
    (feature: 'Area', preset: 'areaMetric', input: '1 500 000 m²', value: 1500000, options: CompactFormatOptions(format: areaMetric)),
    (feature: 'Mass', preset: 'massMetric', input: '0.0000025 g', value: Decimal.parse('0.0000025'), options: CompactFormatOptions(format: massMetric)),
    (feature: 'Precision & rounding', preset: 'Half even · 1 fraction digit', input: '−1 250', value: -1250, options: CompactFormatOptions(format: narrowNatural, precision: const CompactPrecision.fraction(maximum: 1), rounding: CompactRounding.halfEven)),
  ];

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFbde3ff);
    const background = Color(0xFFfbf9ff);
    const ink = Color(0xFF252936);
    const secondary = Color(0xFF596273);
    const radius = BorderRadius.all(Radius.circular(14));
    const side = BorderSide(color: accent);
    Widget text(String value, {double size = 20, bool bold = false, Color color = ink}) => Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: color),
    );
    Widget feature(String title, String subtitle) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        text(title, bold: true),
        const SizedBox(height: 8),
        if (subtitle.contains(' '))
          text(subtitle, size: 14, color: secondary)
        else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: text(subtitle, size: 14, color: secondary),
          ),
      ],
    );
    Widget result(Object value, CompactFormatOptions options) => FittedBox(
      fit: BoxFit.scaleDown,
      child: text(compactFormat(value, options: options), size: 28, bold: true),
    );
    Widget cell(Widget child, double height, {bool fit = false}) => SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: fit
            ? LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(width: constraints.maxWidth, child: child),
                ),
              )
            : Center(child: child),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final paired = constraints.maxWidth >= 900 && MediaQuery.textScalerOf(context).scale(20) <= 24;
              return RepaintBoundary(
                key: const ValueKey('feature-showcase'),
                child: ColoredBox(
                  color: background,
                  child: SizedBox(
                    height: paired ? constraints.maxWidth : null,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          text('any_compact_format', size: paired ? 36 : 28, bold: true),
                          const SizedBox(height: 8),
                          text('Tiny decimals. Huge integers. Everyday units.', size: 18, color: secondary),
                          const SizedBox(height: 28),
                          if (paired)
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  const headerHeight = 64.0;
                                  final rowCount = _samples.length ~/ 2;
                                  final rowHeight = (constraints.maxHeight - headerHeight) / rowCount;
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (var half = 0; half < 2; half++) ...[
                                        if (half > 0) const SizedBox(width: 16),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: radius,
                                            child: Table(
                                              border: const TableBorder(top: side, right: side, bottom: side, left: side, horizontalInside: side, verticalInside: side, borderRadius: radius),
                                              columnWidths: const {0: FlexColumnWidth(1.05), 1: FlexColumnWidth(1.45), 2: FlexColumnWidth(1.1)},
                                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                              children: [
                                                TableRow(
                                                  decoration: const BoxDecoration(color: accent),
                                                  children: [
                                                    for (final label in ['Feature', 'Input', 'Result']) cell(text(label, size: 18, color: secondary), headerHeight),
                                                  ],
                                                ),
                                                for (var row = 0; row < rowCount; row++)
                                                  TableRow(
                                                    children: [
                                                      cell(feature(_samples[row * 2 + half].feature, _samples[row * 2 + half].preset), rowHeight, fit: true),
                                                      cell(text(_samples[row * 2 + half].input, size: 18, color: secondary), rowHeight),
                                                      cell(result(_samples[row * 2 + half].value, _samples[row * 2 + half].options), rowHeight),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            )
                          else
                            for (final sample in _samples)
                              Container(
                                key: ValueKey('showcase-${sample.feature}'),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: accent),
                                  borderRadius: radius,
                                ),
                                child: Column(
                                  children: [
                                    feature(sample.feature, sample.preset),
                                    const SizedBox(height: 16),
                                    text(sample.input, size: 18, color: secondary),
                                    const SizedBox(height: 16),
                                    result(sample.value, sample.options),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotationComparison extends StatefulWidget {
  const _NotationComparison();

  @override
  State<_NotationComparison> createState() => _NotationComparisonState();
}

class _NotationComparisonState extends State<_NotationComparison> {
  static final _formats = {
    'localized': localizedCompact,
    'narrow': narrowCompact,
    'narrowNatural': narrowNatural,
    'subscript': subscriptCompact,
    'zeroSubscript': zeroSubscriptCompact,
    'zeroSuperscript': zeroSuperscriptCompact,
    'scientific': scientificCompact,
    'engineering': engineeringCompact,
  };
  static const _precisions = {
    '2 significant': CompactPrecision.significant(maximum: 2),
    '1 fraction digit': CompactPrecision.fraction(maximum: 1),
    '3 significant': CompactPrecision.significant(maximum: 3),
    '6 significant': CompactPrecision.significant(maximum: 6),
    'Exactly 3 significant': CompactPrecision.significant(minimum: 3, maximum: 3),
    '2 fraction digits': CompactPrecision.fraction(maximum: 2),
    'Exactly 2 fraction digits': CompactPrecision.fraction(minimum: 2, maximum: 2),
  };
  static final _samples = <(String, Object)>[
    ('Zero', Decimal.zero),
    ('Trailing zeros', BigInt.parse('213000000')),
    for (final value in ['1.25', '-1.25', '1.35', '-1.35', '999.5', '-999500', '999500000000', '0.000009999', '-0.00000123456789', '1.234567890123456789', '21300000000000']) (value, Decimal.parse(value)),
    ('BigInt · 10^400', BigInt.from(10).pow(400)),
    ('Decimal · 10^-1000', Decimal.parse('1e-1000')),
    for (var exponent = -36; exponent <= 36; exponent++)
      for (final sign in ['', '-']) ('${sign}10^${exponent > 0 ? '+' : ''}$exponent', Decimal.parse('${sign}1e$exponent')),
  ];
  static final _measurements = <String, (String, CompactFormatDefinition)>{
    'Length · metres': ('lengthMetric', lengthMetric),
    'Area · square metres': ('areaMetric', areaMetric),
    'Volume · cubic metres': ('volumeMetric', volumeMetric),
    'Liquid volume · litres': ('volumeLitres', volumeLitres),
    'Mass · grams': ('massMetric', massMetric),
  };
  static final _measurementSamples = <(String, Object)>[
    ('0', Decimal.zero),
    for (final value in ['0.000000001', '0.000001', '0.001', '0.01', '0.1', '1', '1.25', '999.5', '1500', '1000000', '1000000000'])
      for (final sign in ['', '-']) ('$sign$value', Decimal.parse('$sign$value')),
    ('Beyond largest unit', BigInt.from(10).pow(36)),
    ('Below smallest unit', Decimal.parse('1e-36')),
  ];
  static final _digits = '1234567890' * 4;
  static final _sampleSets = <String, List<(String, Object)>>{
    'Scattered & powers': _samples,
    'File sizes · bytes': [
      ('0', BigInt.zero),
      for (final bytes in ['1', '512', '999', '1000', '1023', '1024', '1280', '1500', '1536', '999999', '1048575', '1048576', '1073741824'])
        for (final sign in ['', '-']) ('$sign$bytes', BigInt.parse('$sign$bytes')),
      ('Fractional bytes', Decimal.parse('0.125')),
      ('Just below KiB', Decimal.parse('1023.999999999999999999999')),
      ('1 YiB', BigInt.from(1024).pow(8)),
      ('Beyond YiB', BigInt.from(1024).pow(9)),
      ('1 QB', BigInt.from(1000).pow(10)),
      ('Beyond QB', BigInt.from(1000).pow(11)),
    ],
    'Growing integers · 0…+36': [
      for (var length = 1; length <= 37; length++)
        for (final sign in ['', '-']) ('$sign${_digits.substring(0, length).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]} ')}', BigInt.parse('$sign${_digits.substring(0, length)}')),
    ],
    'Growing fractions · 1…36 digits': [
      for (var length = 1; length <= 36; length++)
        for (final sign in ['', '-']) ('${sign}0.${_digits.substring(0, length)}', Decimal.parse('${sign}0.${_digits.substring(0, length)}')),
    ],
    'Leading zeros · −1…−36': [
      for (var exponent = 1; exponent <= 36; exponent++)
        for (final sign in ['', '-']) ('${sign}0.${'0' * (exponent - 1)}123456789', Decimal.parse('${sign}0.${'0' * (exponent - 1)}123456789')),
    ],
    for (final name in _measurements.keys) name: _measurementSamples,
  };
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  String _precision = '3 significant';
  CompactRounding _rounding = CompactRounding.halfAwayFromZero;
  String _locale = 'en';
  String _sampleSet = 'Scattered & powers';

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final samples = _sampleSets[_sampleSet]!;
    final fileSizes = _sampleSet == 'File sizes · bytes';
    final measurement = _measurements[_sampleSet];
    final formats = measurement != null
        ? {measurement.$1: measurement.$2}
        : fileSizes
        ? {'fileSizeBinary': fileSizeBinary, 'fileSizeDecimal': fileSizeDecimal}
        : _formats;
    final inputWidth = _sampleSet == 'Scattered & powers' ? 190.0 : 420.0;
    Widget cell(String text, {bool header = false, String? tooltip, double width = 190}) => SizedBox(
      width: width,
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: tooltip ?? text,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: header ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ),
      ),
    );
    return Padding(
      key: const ValueKey('notation-comparison'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compare every notation', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Exact Decimal and BigInt inputs · choose powers, growing 1234567890 digits, growing fractions or leading zeros across −36…+36. Each sequence pairs a positive value with its negative counterpart. Scroll across to compare; hover a value for its full text.',
          ),
          const SizedBox(height: 8),
          const Text('2130₆0 and 2130⁶0 mean 213 followed by exactly six zeros: 213000000. Both visible zeros are markers for that run. Precision applies to the coefficient; fractional precision can round tiny values to zero.'),
          if (fileSizes) const Text('Inputs are bytes. Binary steps use 1024 (KiB, MiB…YiB); decimal steps use 1000 (kB, MB…QB). Try 2 fraction digits to inspect rounding near unit boundaries. Zero keeps B; larger values retain the last unit.'),
          if (measurement != null) Text('Input: ${_sampleSet.split(' · ').last}. Select en or uk_UA to compare the default English catalog and the separately imported Ukrainian catalog. Zero keeps the input unit.'),
          Wrap(
            spacing: 24,
            children: [
              SizedBox(
                width: 320,
                child: DropdownButton<String>(
                  isExpanded: true,
                  key: const ValueKey('notation-samples'),
                  value: _sampleSet,
                  items: [
                    for (final name in _sampleSets.keys)
                      DropdownMenuItem(
                        value: name,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _sampleSet = value!;
                    _vertical.jumpTo(0);
                    _horizontal.jumpTo(0);
                  }),
                ),
              ),
              SizedBox(
                width: 90,
                child: DropdownButton<String>(
                  isExpanded: true,
                  key: const ValueKey('notation-locale'),
                  value: _locale,
                  items: [
                    for (final locale in ['en', 'nb', 'uk']) DropdownMenuItem(value: locale, child: Text(locale == 'uk' ? 'uk_UA' : locale)),
                  ],
                  onChanged: (value) => setState(() => _locale = value!),
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButton<String>(
                  isExpanded: true,
                  key: const ValueKey('notation-precision'),
                  value: _precision,
                  items: [
                    for (final name in _precisions.keys)
                      DropdownMenuItem(
                        value: name,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _precision = value!),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButton<CompactRounding>(
                  isExpanded: true,
                  key: const ValueKey('notation-rounding'),
                  value: _rounding,
                  items: [for (final mode in CompactRounding.values) DropdownMenuItem(value: mode, child: Text(mode.name))],
                  onChanged: (value) => setState(() => _rounding = value!),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 580,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: inputWidth + 190 * formats.length,
                  child: Column(
                    children: [
                      ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Row(
                          children: [
                            cell('Input', header: true, width: inputWidth),
                            for (final name in formats.keys) cell(name, header: true),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('notation-rows'),
                          controller: _vertical,
                          child: Column(
                            children: [
                              for (var index = 0; index < samples.length; index++)
                                ColoredBox(
                                  color: index.isEven ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerLow,
                                  child: Row(
                                    key: ValueKey('notation-row-${samples[index].$1}'),
                                    children: [
                                      cell(samples[index].$1, tooltip: samples[index].$2.toString(), width: inputWidth),
                                      for (final format in formats.values)
                                        cell(
                                          context.compactFormat(
                                            samples[index].$2,
                                            options: CompactFormatOptions(
                                              locale: _locale == 'uk' ? uk.locale.copyWith(locale: const Locale('uk', 'UA')) : en.locale.copyWith(locale: Locale(_locale)),
                                              format: format,
                                              precision: _precisions[_precision],
                                              rounding: _rounding,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocaleComparison extends StatefulWidget {
  const _LocaleComparison();

  @override
  State<_LocaleComparison> createState() => _LocaleComparisonState();
}

class _LocaleComparisonState extends State<_LocaleComparison> {
  static final _locales = <String, ({String name, CompactLocale configuration})>{
    'bg': (name: 'Bulgarian', configuration: bg.locale),
    'cs': (name: 'Czech', configuration: cs.locale),
    'de': (name: 'German', configuration: de.locale),
    'en': (name: 'English', configuration: en.locale),
    'es': (name: 'Spanish', configuration: es.locale),
    'fr': (name: 'French', configuration: fr.locale),
    'hi': (name: 'Hindi', configuration: hi.locale),
    'hu': (name: 'Hungarian', configuration: hu.locale),
    'id': (name: 'Indonesian', configuration: id.locale),
    'it': (name: 'Italian', configuration: it.locale),
    'ja': (name: 'Japanese', configuration: ja.locale),
    'ko': (name: 'Korean', configuration: ko.locale),
    'nl': (name: 'Dutch', configuration: nl.locale),
    'pl': (name: 'Polish', configuration: pl.locale),
    'pt': (name: 'Portuguese (Brazil)', configuration: pt.locale),
    'pt_pt': (name: 'Portuguese (Portugal)', configuration: pt_pt.locale),
    'ro': (name: 'Romanian', configuration: ro.locale),
    'ru': (name: 'Russian', configuration: ru.locale),
    'sk': (name: 'Slovak', configuration: sk.locale),
    'sv': (name: 'Swedish', configuration: sv.locale),
    'tr': (name: 'Turkish', configuration: tr.locale),
    'uk': (name: 'Ukrainian', configuration: uk.locale),
    'vi': (name: 'Vietnamese', configuration: vi.locale),
    'zh': (name: 'Chinese (Simplified)', configuration: zh.locale),
    'nb': (name: 'Norwegian Bokmål', configuration: en.locale.copyWith(locale: const Locale('nb'))),
  };
  String _selectedLocale = 'en';

  @override
  Widget build(BuildContext context) {
    final locale = _locales[_selectedLocale]!.configuration;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('comparison-locale'),
                    initialValue: _selectedLocale,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Locale', border: OutlineInputBorder()),
                    items: [
                      for (final entry in _locales.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text('${entry.value.name} (${entry.value.configuration.locale})', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLocale = value);
                    },
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final format in {'localized': localizedCompact, 'narrow': narrowCompact}.entries) ...[
                        if (format.key == 'narrow') const SizedBox(width: 16),
                        Expanded(
                          child: _ExampleCell(key: ValueKey('$_selectedLocale-${format.key}'), locale: locale, formatName: format.key, format: format.value),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleCell extends StatelessWidget {
  final CompactLocale locale;
  final String formatName;
  final CompactFormatDefinition format;
  const _ExampleCell({super.key, required this.locale, required this.formatName, required this.format});

  @override
  Widget build(BuildContext context) {
    final millions = CompactFormatDefinition(
      base: format,
      overrides: [CompactInterval(from: CompactPower(power: 6), to: CompactPower(power: 9), scale: CompactPower(power: 6), suffix: ' million', formatter: (context) => context.decimalValue == Decimal.one ? '${context.defaultText} exactly' : null)],
    );
    final symbols = CompactFormatDefinition(
      base: format,
      overrides: const [CompactInterval(from: CompactPower(power: 9), to: CompactPower(power: 12), scale: CompactPower(power: 9), suffix: 'bn')],
    );
    final regional = CompactFormatDefinition(
      base: format,
      overrides: const [
        CompactInterval(to: CompactPower(power: 3), scale: CompactPower(power: 0)),
        CompactInterval(from: CompactPower(power: 3), scale: CompactPower(power: 3), suffix: ' k'),
        CompactInterval(from: CompactPower(power: 5), scale: CompactPower(power: 5), suffix: ' L'),
        CompactInterval(from: CompactPower(power: 7), to: CompactPower(power: 9), scale: CompactPower(power: 7), suffix: ' Cr'),
      ],
    );
    final noSmall = CompactFormatDefinition(
      base: format,
      overrides: const [CompactInterval(to: CompactPower(power: 0), scale: CompactPower(power: 0))],
    );
    final custom = CompactFormatDefinition(base: format, formatter: (context) => context.value == 42 ? 'Value ${context.numberText}' : null);

    Widget row(String id, String label, Widget value, {String? description}) => Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          if (description != null) Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
    Widget number(String id, String label, num value, {CompactFormatOptions? options, String? description}) => row(id, label, CompactFormatText(value, options: options), description: description);

    return CompactFormatProvider(
      options: CompactFormatOptions(locale: locale, format: format),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${locale.locale} · $formatName', style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            number('default', 'Default · 1234567', 1234567),
            number('billions', 'Billions · 1000000000', 1e9),
            number('milli', 'Milli · 0.001', 0.001),
            number('micro', 'Micro · 0.000001', 0.000001),
            number('two-digits', 'Up to two significant digits · 1234567', 1234567, options: const CompactFormatOptions(precision: CompactPrecision.significant(maximum: 2))),
            number(
              'three-significant-digits',
              'Exactly three significant digits · 12000',
              12000,
              description: 'Count digits on both sides of the decimal separator, excluding leading zeros. Add trailing zeros if needed.',
              options: const CompactFormatOptions(precision: CompactPrecision.significant(minimum: 3, maximum: 3)),
            ),
            number(
              'two-decimal-places',
              'Exactly two decimal places · 12500',
              12500,
              description: 'Keep two digits after the decimal separator, regardless of how many come before it. Add trailing zeros if needed.',
              options: const CompactFormatOptions(precision: CompactPrecision.fraction(minimum: 2, maximum: 2)),
            ),
            number('boundary', 'Rounding boundary · 999950', 999950),
            number('negative', 'Negative · -1234567', -1234567),
            number('sign', 'Explicit sign · 1200', 1200, options: const CompactFormatOptions(explicitSign: true)),
            for (final sample in <(String, String, num)>[
              ('below-override', 'Below the override · 1200', 1200),
              ('interval-callback', 'Interval callback · 1000000', 1000000),
              ('null-interval', 'Null callback keeps interval text · 1234567', 1234567),
              ('millions-boundary', 'Rounding leaves override · 999950000', 999950000),
              ('above-override', 'Above the override · 1000000000', 1000000000),
            ])
              number(sample.$1, sample.$2, sample.$3, options: CompactFormatOptions(format: millions)),
            number('symbol', 'Symbol override · 1000000000', 1e9, options: CompactFormatOptions(format: symbols)),
            number('regional', 'Custom intervals · 123456', 123456, options: CompactFormatOptions(format: regional)),
            number('unscaled', 'Unscaled sub-unit interval · 0.000001', 0.000001, options: CompactFormatOptions(format: noSmall)),
            CompactFormatProvider(
              options: const CompactFormatOptions(precision: CompactPrecision.significant(maximum: 2)),
              child: number('nested', 'Nested provider inherits format + two digits · 1234567', 1234567),
            ),
            row('builder', 'Builder · 1200', Builder(builder: (context) => Text(context.compactFormat(1200)))),
            number('custom', 'Custom formatter · 42', 42, options: CompactFormatOptions(format: custom)),
            number('null-custom', 'Custom formatter delegates null to base · 1200', 1200, options: CompactFormatOptions(format: custom)),
          ],
        ),
      ),
    );
  }
}
