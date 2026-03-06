When the compiler reports the OverlappingNamesInLet ("DuplicateDeclarationsInLet") error for duplicate declarations in a `let`/`where` binding group, the diagnostic does not provide enough structured information for tooling, and it highlights an unhelpful source location.

Currently, the error should identify which name was duplicated, and it should prefer pointing at the last duplicate declaration (the later occurrence) as the primary error span, since that location is generally the most useful in editors and command-line output.

Fix the OverlappingNamesInLet / DuplicateDeclarationsInLet error so that:

- The error message includes the duplicated identifier name (e.g. "The name a was defined multiple times in a binding group" and similarly for other identifiers like `interrupted`).
- The primary reported span/position for the error corresponds to the last duplicate declaration rather than the first.
- The JSON error output includes an `allSpans` (or equivalent) collection containing source spans for all duplicate declarations involved in the error, not just the primary one. Each span should point to the declaration site in the source.
- If multiple different names are duplicated in the same binding group, the compiler should report separate errors for each duplicated name (e.g. one error for `a` and another for `interrupted`), each with its own primary span (the last duplicate for that name) and its own list of all spans for that name.

Example scenarios that must work:

1) Duplicate value + type signature in a `where` block:
```purescript
foo = a
  where
  a :: Number
  a = 1

  a :: Number
  a = 2
```
This should produce OverlappingNamesInLet for `a`, with the primary location pointing at the later `a :: Number` declaration, and the JSON should include both declaration spans.

2) Duplicate function equations separated by other bindings:
```purescript
foo = interrupted
  where
  interrupted true = 1
  interrupter = 2
  interrupted false = 3
```
This should produce OverlappingNamesInLet for `interrupted`, with the primary location pointing at the later equation (`interrupted false = 3`), and the JSON should include both spans.

3) Multiple duplicated names in the same `where` block:
```purescript
foo = interrupter + a
  where
  a = 0
  a :: Int
  a = 0

  interrupted true = 1
  interrupter = 2
  interrupted false = 3
```
This should produce two separate OverlappingNamesInLet errors: one for `a` and one for `interrupted`, each with appropriate primary span ordering and `allSpans` covering all duplicates for that name.