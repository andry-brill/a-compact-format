import 'package:flutter/foundation.dart';

/// Semantic label identity, independent of its spelling or locale.
/// Custom labels should use an application-owned namespace.
@immutable
final class CompactLabel {
  final String key;
  const CompactLabel(this.key);

  static const quecto = CompactLabel('prefix.quecto');
  static const ronto = CompactLabel('prefix.ronto');
  static const yocto = CompactLabel('prefix.yocto');
  static const zepto = CompactLabel('prefix.zepto');
  static const atto = CompactLabel('prefix.atto');
  static const femto = CompactLabel('prefix.femto');
  static const pico = CompactLabel('prefix.pico');
  static const nano = CompactLabel('prefix.nano');
  static const micro = CompactLabel('prefix.micro');
  static const milli = CompactLabel('prefix.milli');
  static const thousand = CompactLabel('number.thousand');
  static const million = CompactLabel('number.million');
  static const billion = CompactLabel('number.billion');
  static const trillion = CompactLabel('number.trillion');
  static const quadrillion = CompactLabel('number.quadrillion');
  static const quintillion = CompactLabel('number.quintillion');
  static const sextillion = CompactLabel('number.sextillion');
  static const septillion = CompactLabel('number.septillion');
  static const octillion = CompactLabel('number.octillion');
  static const nonillion = CompactLabel('number.nonillion');
  static const byte = CompactLabel('data.byte');
  static const kilobyte = CompactLabel('data.kilobyte');
  static const megabyte = CompactLabel('data.megabyte');
  static const gigabyte = CompactLabel('data.gigabyte');
  static const terabyte = CompactLabel('data.terabyte');
  static const petabyte = CompactLabel('data.petabyte');
  static const exabyte = CompactLabel('data.exabyte');
  static const zettabyte = CompactLabel('data.zettabyte');
  static const yottabyte = CompactLabel('data.yottabyte');
  static const ronnabyte = CompactLabel('data.ronnabyte');
  static const quettabyte = CompactLabel('data.quettabyte');
  static const kibibyte = CompactLabel('data.kibibyte');
  static const mebibyte = CompactLabel('data.mebibyte');
  static const gibibyte = CompactLabel('data.gibibyte');
  static const tebibyte = CompactLabel('data.tebibyte');
  static const pebibyte = CompactLabel('data.pebibyte');
  static const exbibyte = CompactLabel('data.exbibyte');
  static const zebibyte = CompactLabel('data.zebibyte');
  static const yobibyte = CompactLabel('data.yobibyte');

  static const micrometre = CompactLabel('length.micrometre');
  static const millimetre = CompactLabel('length.millimetre');
  static const centimetre = CompactLabel('length.centimetre');
  static const metre = CompactLabel('length.metre');
  static const kilometre = CompactLabel('length.kilometre');
  static const squareMillimetre = CompactLabel('area.squareMillimetre');
  static const squareCentimetre = CompactLabel('area.squareCentimetre');
  static const squareMetre = CompactLabel('area.squareMetre');
  static const squareKilometre = CompactLabel('area.squareKilometre');
  static const cubicMillimetre = CompactLabel('volume.cubicMillimetre');
  static const cubicCentimetre = CompactLabel('volume.cubicCentimetre');
  static const cubicMetre = CompactLabel('volume.cubicMetre');
  static const cubicKilometre = CompactLabel('volume.cubicKilometre');
  static const microlitre = CompactLabel('volume.microlitre');
  static const millilitre = CompactLabel('volume.millilitre');
  static const centilitre = CompactLabel('volume.centilitre');
  static const decilitre = CompactLabel('volume.decilitre');
  static const litre = CompactLabel('volume.litre');
  static const hectolitre = CompactLabel('volume.hectolitre');
  static const kilolitre = CompactLabel('volume.kilolitre');
  static const microgram = CompactLabel('mass.microgram');
  static const milligram = CompactLabel('mass.milligram');
  static const gram = CompactLabel('mass.gram');
  static const kilogram = CompactLabel('mass.kilogram');
  static const tonne = CompactLabel('mass.tonne');

  @override
  bool operator ==(Object other) => other is CompactLabel && key == other.key;
  @override
  int get hashCode => key.hashCode;
}
