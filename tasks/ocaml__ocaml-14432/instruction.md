OCaml’s standard integer modules need to provide additional, well-defined integer division operations that cover common mathematical division semantics, especially a non-negative modulo suitable for modular arithmetic.

Currently, the standard truncating division and remainder operations (`div`/`rem`) follow round-toward-zero division, which yields negative remainders for negative dividends (e.g. `(4 - 5) mod 3` producing `-1` rather than a canonical representative in `{0..2}`). This makes it awkward to implement modulo arithmetic where the remainder is expected to be non-negative.

Add the following functions to the integer modules (at minimum `Int` and `Int64`, and consistently for `Int32`/`Nativeint` if they are part of the change scope):

- `fdiv : t -> t -> t` — floor division (quotient rounded down toward negative infinity).
- `cdiv : t -> t -> t` — ceil division (quotient rounded up toward positive infinity).
- `ediv : t -> t -> t` — Euclidean division quotient.
- `erem : t -> t -> t` — Euclidean remainder.

Required semantics:

1) Division by zero behavior

For any of `div`, `rem`, `fdiv`, `cdiv`, `ediv`, `erem`, when the divisor is zero, calling the function must raise `Division_by_zero`.

2) Truncating division identity remains valid

For nonzero divisor `y`, truncating division must satisfy the standard identity:

- Let `q = div x y` and `r = rem x y`.
- Must hold: `x = q * y + r`.
- Additionally, the magnitude of the truncating remainder must be bounded: `abs r <= abs y - 1`.

3) Euclidean division/remainder identity and range

For nonzero divisor `y`, Euclidean division must satisfy:

- Let `q' = ediv x y` and `r' = erem x y`.
- Must hold: `x = q' * y + r'`.
- The Euclidean remainder must be the canonical non-negative remainder:
  - `0 <= r'` and `r' <= abs y - 1`.

This ensures `erem` is appropriate for modulo arithmetic: `erem p q` is the unique integer in `{0, ..., |q|-1}` congruent to `p` modulo `q`.

4) Relationship between floor/ceil division and truncating division

For nonzero divisor `y`, the three quotients must be ordered consistently:

- Let `q = div x y`, `f = fdiv x y`, `c = cdiv x y`.
- Must hold: `f <= q` and `q <= c`.
- If `rem x y = 0`, then all three agree: `f = q` and `q = c`.

5) Relationship between Euclidean quotient and floor/ceil quotient

The Euclidean quotient must align with floor or ceil depending on the sign of the divisor:

- For nonzero `y`: `ediv x y = (if y > 0 then fdiv x y else cdiv x y)`.

Example motivation that must work with these semantics:

- With `p = 4 - 5` and `q = 3`, Euclidean remainder should produce the modulo-arithmetic representative:
  - `erem p q` should be `2` (and never negative for nonzero `q`).

Implement these functions with correct edge-case behavior across the full integer range (including minimum/maximum values) and ensure they behave consistently with existing arithmetic identities.