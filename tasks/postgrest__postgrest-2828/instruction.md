The `PostgREST.MediaType` data model currently includes a recursive constructor (`MTPlan`) that can embed another `MediaType`. This recursion prevents a usable `Show` instance from being derived for `MediaType` (and/or causes compilation failures around `StandaloneDeriving`), which in turn makes it impractical to add and run doctests against the MediaType-related code.

The media type representation should be refactored so that “plan” media types are represented without allowing a `MediaType` to contain another `MediaType`. Introduce a separate type for non-plan media types (named `NormalMedia`) and adjust `MediaType` so that plan-related constructors no longer create a recursive structure.

After this change:

- `MediaType` must have a working `Show` instance that can be derived successfully.
- `NormalMedia` must be exported and usable by other modules that previously relied on the recursive structure.
- Existing code that pattern-matches or constructs media types must continue to work with the new representation (e.g., code importing `MediaType(..)` should be updated to use `NormalMedia(..)` where appropriate).
- Doctest examples for the media type parsing/printing behavior should compile and run successfully with `MediaType`/`NormalMedia` available.

If the recursion is still present (directly or indirectly), deriving `Show` and running doctests will fail; the goal is to remove that recursion while preserving the ability to represent plan vs non-plan media types cleanly via `MediaType` and `NormalMedia`.