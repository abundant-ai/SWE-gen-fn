Dune’s byte-size unit handling is incomplete: users can’t reliably parse and display binary byte units alongside the existing decimal units.

When parsing byte quantities from Dune language atoms/strings using `Dune_sexp.Decoder.bytes_unit`, the decoder should accept both decimal units and binary units. Supported suffixes must include `B`, `kB`, `KiB`, `MB`, `MiB`, `GB`, `GiB`, `TB`, and `TiB`. If the input has no suffix (e.g. `"100"`), parsing must fail with an error that explicitly says the suffix is missing and lists the allowed suffixes exactly: `missing suffix, use one of B, kB, KiB, MB, MiB, GB, GiB, TB, TiB`.

The numeric meaning of the suffixes must be correct:
- `1B` parses to `1`.
- Decimal units use powers of 1000: `1kB = 1000`, `1MB = 1000^2`, `1GB = 1000^3`, `1TB = 1000^4`.
- Binary units use powers of 1024: `1KiB = 1024`, `1MiB = 1024^2`, `1GiB = 1024^3`, `1TiB = 1024^4`.

Separately, `Stdune.Bytes_unit.pp` (pretty-printing an `int64` byte count) should default to printing decimal units like before (e.g. `kB/MB/GB/TB`), not binary units. The formatted output should use two decimal places for scaled values and switch units at the expected boundaries so that, for example:
- `1234L` prints as `1.23kB`
- `1234567L` prints as `1.23MB`
- `1234567890123456L` prints as `1234.57TB`
- Small values stay in bytes: `0L -> 0B`, `12L -> 12B`, `123L -> 123B`.

The `Bytes_unit.conversion_table` must remain well-formed: it must be sorted by the numeric multiplier (ascending), and each entry must have a non-empty list of suffixes.

Finally, the `dune cache trim` command documentation/help text must describe `--size=BYTES` and `--trimmed-size=BYTES` as accepting a byte count followed by a unit, and the unit list shown to users must include the binary units (`KiB`, `MiB`, `GiB`, `TiB`) alongside the existing decimal ones.