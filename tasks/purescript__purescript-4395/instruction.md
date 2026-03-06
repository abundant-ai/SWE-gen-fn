When deriving `Foldable`, `Traversable`, or similar classes, the compiler can raise `CannotDeriveInvalidConstructorArg` if a type variable appears in an invalid position (i.e., not as the final argument of a type constructor with the required instance). Currently, when a derived instance fails due to multiple offending occurrences of the type variable(s), the compiler produces one separate error per occurrence. This leads to extremely verbose output in terminals and is also problematic for IDE integrations which expect a single diagnostic that can carry multiple source spans.

Change the behavior of `CannotDeriveInvalidConstructorArg` reporting so that all offending occurrences are reported in a single error message/diagnostic rather than multiple errors. The single diagnostic must include multiple source spans corresponding to each invalid occurrence, so tools can attach highlights to each location.

The pretty-printed human output should:

- Keep the existing high-level message text:
  "One or more type variables are in positions that prevent Foldable from being derived. To derive this class, make sure that these variables are only used as the final arguments to type constructors, and that those type constructors themselves have instances of Foldable."
- Show a source excerpt which can highlight more than one occurrence in the surrounding code.
- Highlight every offending type-variable occurrence within the excerpt. When ANSI output is enabled, the highlight should use reverse-video styling; when ANSI output is disabled (including JSON-oriented output modes), the highlight should be represented using ASCII carets on a following line as an underline-like indicator.
- Include at least one line of context before and after every highlighted occurrence in the excerpt.
- If two highlighted occurrences are separated by more than three non-highlighted lines, collapse the gap with an ellipsis line so the output remains readable.

Example scenario that must be handled: a data declaration contains many occurrences of the problematic variable (including within nested records and type applications), and the derived instance fails. The user should see a single `CannotDeriveInvalidConstructorArg` error where the excerpt contains multiple highlighted positions (possibly on multiple lines), instead of many repeated errors.

This change must also be compatible with editor tooling expectations: the diagnostic produced for this error must carry multiple spans/locations rather than requiring separate diagnostics per span.