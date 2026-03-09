Dune should validate package names more strictly starting with language version 3.11, using opam’s package naming conventions, while keeping the previous permissive behavior for earlier language versions.

Currently, when a user defines a package in a dune-project file, invalid opam-style names may be accepted (or produce unhelpful errors) even when using (lang dune 3.11) or newer. The system needs a new strict package-name representation/validation mode and must select it based on the language version.

Implement a `Package_name.Strict` variant that enforces opam package naming rules and is used by the dune-project parser when `(lang dune >= 3.11)`.

Rules for strict opam package names:
- Allowed characters are letters (a-z, A-Z), digits (0-9), and the symbols `-`, `_`, `+`.
- The name must contain at least one letter.
- A name may start with a digit (e.g., `0install` is valid).

Behavior expectations:
1) Version gating
- With `(lang dune 3.10)`, a package name like `some&name` must continue to be accepted (i.e., no strict opam validation error).
- With `(lang dune 3.11)` or newer, the same name must be rejected as invalid.

2) Error message for invalid names (lang >= 3.11)
When a strict name is invalid, Dune must report an error of the form:
- `Error: "<name>" is an invalid opam package name.`
- Followed by an explanation: `Package names can contain letters, numbers, '-', '_' and '+', and need to contain at least a letter.`
- And a `Hint: <suggestion> would be a correct opam package name`

3) Name suggestion
When suggesting a corrected opam package name:
- Replace invalid characters with `_` (e.g., `some&name` should suggest `some_name`).
- If the name starts with characters that cannot be part of an opam name, drop/normalize them so the suggestion becomes valid (e.g., `0test` should not produce an error because it is valid; but leading invalid characters in other cases should be removed rather than preserved).
- If sanitization would remove everything or the result still lacks any letter, the suggestion must be prefixed with `p` to ensure at least one letter (e.g., `0` should suggest `p0`, and `0-9` should suggest `p0-9`).

4) Concrete scenarios that must work (lang dune 3.11)
- `(name some&name)` must fail with the error format above and suggest `some_name`.
- `(name 0)` must fail and suggest `p0`.
- `(name 0-9)` must fail and suggest `p0-9`.
- `(name 0install)` must succeed.

Implementing this requires integrating the strict validation into the dune-project parsing/decoding so the chosen `Package_name` mode depends on the declared language version, and ensuring the produced diagnostics (including source location highlighting and hint text) match the expected format.