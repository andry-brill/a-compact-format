# Changelog

## 1.0.0

- Configurable final fallback rendering through `CompactFormatOptions.fallbackFormatter`, inherited by providers.

- Compact, scientific, engineering, and subscript/superscript zero-count notation, including `narrowNatural`.
- Exact decimal scaling for `num`, `Decimal`, and `BigInt`, with configurable precision and rounding.
- Binary/decimal file sizes and metric length, area, volume, and mass presets.
- 24 locale configurations with customizable narrow magnitude labels, including Brazilian and European Portuguese. Japanese, Simplified Chinese, Korean, and Hindi also include native magnitude interval overrides for merging into formats.
- Extensible intervals, mixed-base powers, callbacks, and Flutter providers/widgets.
