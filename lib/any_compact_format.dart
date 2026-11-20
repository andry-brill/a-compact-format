/// Approximate compact number presentation for Flutter.
library;

export 'package:decimal/decimal.dart' show Decimal;

export 'src/formats.dart'
    show
        localizedCompact,
        narrowCompact,
        subscriptCompact,
        subscriptOverrides,
        zeroSubscriptCompact,
        zeroSuperscriptCompact,
        scientificCompact,
        engineeringCompact,
        narrowNatural,
        fileSizeBinary,
        fileSizeDecimal,
        lengthMetric,
        areaMetric,
        volumeMetric,
        volumeLitres,
        massMetric;
export 'src/notation.dart' show CompactNotation, CompactScript, ZeroCountSides;
export 'src/formatter.dart' show compactFormat, defaultFallbackFormatter, CompactPower, CompactInterval, CompactFormatDefinition, CompactFormatter, CompactFormattingContext;
export 'src/options.dart' show CompactFormatOptions, CompactPrecision, CompactRounding;
export 'src/flutter.dart' show CompactFormatProvider, CompactFormatContext, CompactFormatText;

export 'src/labels.dart' show CompactLabel;
export 'src/locale.dart' show CompactLocale;
