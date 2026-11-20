import 'package:any_compact_format/any_compact_format.dart';
import 'package:any_compact_format/locales/cs.dart' as cs;
import 'package:any_compact_format/locales/sk.dart' as sk;
import 'package:any_compact_format/locales/hu.dart' as hu;
import 'package:any_compact_format/locales/ro.dart' as ro;
import 'package:any_compact_format/locales/bg.dart' as bg;
import 'package:any_compact_format/locales/de.dart' as de;
import 'package:any_compact_format/locales/nl.dart' as nl;
import 'package:any_compact_format/locales/sv.dart' as sv;
import 'package:any_compact_format/locales/es.dart' as es;
import 'package:any_compact_format/locales/pt.dart' as pt;
import 'package:any_compact_format/locales/pt_pt.dart' as pt_pt;
import 'package:any_compact_format/locales/tr.dart' as tr;
import 'package:any_compact_format/locales/id.dart' as id;
import 'package:any_compact_format/locales/vi.dart' as vi;
import 'package:any_compact_format/locales/ja.dart' as ja;
import 'package:any_compact_format/locales/zh.dart' as zh;
import 'package:any_compact_format/locales/ko.dart' as ko;
import 'package:any_compact_format/locales/hi.dart' as hi;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled locales render the four fixed scales and respect overrides', () {
    for (final (standard, narrow, expected, short, override) in [
      (cs.locale, cs.narrow(), 'tis. mil. mld. bil.', 't M Md B', cs.narrow(B: 'custom')),
      (sk.locale, sk.narrow(), 'tis. mil. mld. bil.', 't M Md B', sk.narrow(B: 'custom')),
      (hu.locale, hu.narrow(), 'E M Mrd B', 'E M Md B', hu.narrow(B: 'custom')),
      (ro.locale, ro.narrow(), 'K mil. mld. tril.', 'K M Md T', ro.narrow(B: 'custom')),
      (bg.locale, bg.narrow(), 'хил. млн. млрд. трлн.', 'х М Мд Т', bg.narrow(B: 'custom')),
      (de.locale, de.narrow(), 'Tsd. Mio. Mrd. Bio.', 'Tsd M Md B', de.narrow(B: 'custom')),
      (nl.locale, nl.narrow(), 'K mln. mld. bln.', 'K M Md B', nl.narrow(B: 'custom')),
      (sv.locale, sv.narrow(), 'tn mn md bn', 'tn mn md bn', sv.narrow(B: 'custom')),
      (es.locale, es.narrow(), 'mil M mil M B', 'k M G B', es.narrow(B: 'custom')),
      (pt.locale, pt.narrow(), 'mil mi bi tri', 'k M B T', pt.narrow(B: 'custom')),
      (pt_pt.locale, pt_pt.narrow(), 'mil M mM Bi', 'k M mM Bi', pt_pt.narrow(B: 'custom')),
      (tr.locale, tr.narrow(), 'B Mn Mr Tn', 'B Mn Mr Tn', tr.narrow(B: 'custom')),
      (id.locale, id.narrow(), 'rb jt M T', 'rb jt M T', id.narrow(B: 'custom')),
      (vi.locale, vi.narrow(), 'N Tr T NT', 'N Tr T NT', vi.narrow(B: 'custom')),
      (ja.locale, ja.narrow(), 'k M B 兆', 'k M B 兆', ja.narrow(B: 'custom')),
      (zh.locale, zh.narrow(), 'k M B 万亿', 'k M B 万亿', zh.narrow(B: 'custom')),
      (ko.locale, ko.narrow(), '천 M B 조', '천 M B 조', ko.narrow(B: 'custom')),
      (hi.locale, hi.narrow(), 'हज़ार M अ॰ T', 'ह M अ॰ T', hi.narrow(B: 'custom')),
    ]) {
      final values = [1000, 1000000, 1000000000, 1000000000000];
      for (final (locale, labels) in [(standard, expected), (narrow, short)]) {
        final options = CompactFormatOptions(locale: locale, format: narrowCompact);
        expect(values.map((v) => compactFormat(v, options: options)), labels.split(' ').map((s) => '1$s'), reason: locale.locale.toString());
      }
      expect(
        compactFormat(
          1e9,
          options: CompactFormatOptions(locale: override, format: narrowCompact),
        ),
        '1custom',
      );
    }
  });

  test('native scales select and promote at local magnitude boundaries', () {
    for (final (locale, format, boundaries) in [
      (ja.locale, narrowNatural.copyWith(overrides: ja.narrowOverrides), {4: '万', 8: '億', 12: '兆', 16: '京'}),
      (zh.locale, narrowNatural.copyWith(overrides: zh.narrowOverrides), {4: '万', 8: '亿', 12: '万亿'}),
      (ko.locale, narrowNatural.copyWith(overrides: ko.narrowOverrides), {3: '천', 4: '만', 8: '억', 12: '조'}),
      (hi.locale, narrowNatural.copyWith(overrides: hi.narrowOverrides), {3: 'हज़ार', 5: 'लाख', 7: 'क॰', 9: 'अ॰', 11: 'ख॰', 13: 'नील'}),
    ]) {
      final options = CompactFormatOptions(locale: locale, format: format);
      for (final entry in boundaries.entries) {
        final boundary = BigInt.from(10).pow(entry.key);
        expect(compactFormat(boundary, options: options), '1${entry.value}');
        expect(compactFormat(-boundary, options: options), '-1${entry.value}');
        if (entry.key > 3) expect(compactFormat(boundary - BigInt.one, options: options), '1${entry.value}');
      }
    }
    expect(
      compactFormat(
        15000,
        options: CompactFormatOptions(
          locale: ja.locale,
          format: narrowNatural.copyWith(overrides: ja.narrowOverrides),
        ),
      ),
      '1.5万',
    );
    expect(
      compactFormat(
        150000,
        options: CompactFormatOptions(
          locale: hi.locale,
          format: narrowNatural.copyWith(overrides: hi.narrowOverrides),
        ),
      ),
      '1.5लाख',
    );
  });

  test('native overrides preserve smaller base values and replace the full upper range', () {
    for (final (locale, overrides, lastPower, lastLabel) in [(ja.locale, ja.narrowOverrides, 16, '京'), (zh.locale, zh.narrowOverrides, 12, '万亿'), (ko.locale, ko.narrowOverrides, 12, '조'), (hi.locale, hi.narrowOverrides, 13, 'नील')]) {
      final merged = CompactFormatOptions(
        locale: locale,
        format: narrowNatural.copyWith(overrides: overrides),
      );
      final standalone = merged.copyWith(format: CompactFormatDefinition(overrides: overrides));
      expect(compactFormat(1e-36, options: merged), '0.0₃₅1');
      expect(compactFormat(1e-36, options: standalone), '0');
      expect(compactFormat(15, options: standalone), '15');
      final huge = BigInt.from(10).pow(36);
      final expected = '${BigInt.from(10).pow(36 - lastPower)}$lastLabel';
      expect(compactFormat(huge, options: merged), expected);
      expect(compactFormat(huge, options: standalone), expected);
    }
    final japanese = CompactFormatOptions(
      locale: ja.narrow(),
      format: narrowCompact.copyWith(overrides: ja.narrowOverrides),
    );
    expect(compactFormat(0.0000015, options: japanese), '1.5µ');
    expect(compactFormat(1500, options: japanese), '1.5k');
    expect(
      compactFormat(
        1500,
        options: japanese.copyWith(format: CompactFormatDefinition(overrides: ja.narrowOverrides)),
      ),
      '1500',
    );
  });
}
