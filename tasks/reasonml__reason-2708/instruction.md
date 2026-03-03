Formatting polymorphic variant types is inconsistent with how normal variants are printed. When `refmt` prints Reason code containing a polymorphic variant type written inline with bracket syntax, it keeps everything on one line instead of breaking into a multi-line, variant-like layout.

For example, given:

```reason
type foo = [ | `utf8 | `my_name]
```

`refmt` currently prints it in a single line (or otherwise does not break it as a variant list). It should format it similarly to normal variants, producing:

```reason
type foo = [
  | `utf8
  | `my_name
]
```

The same behavior should apply to other polymorphic variant type aliases such as:

```reason
type align = [ | `Start | `End | `Center];

type justify = [ | `Around | `Between | `Evenly | `Start | `Center | `End];
```

They should be printed with one constructor per line inside `[` `]`, preserving backticks:

```reason
type align = [
  | `Start
  | `End
  | `Center
];

type justify = [
  | `Around
  | `Between
  | `Evenly
  | `Start
  | `Center
  | `End
];
```

This change must not break cases where polymorphic variants are intentionally inlined within other type expressions (e.g., within an `external` declaration’s argument type). In those contexts, `refmt` should continue to apply sensible line-breaking heuristics so that short inline polymorphic variant types can remain inline, while longer ones can still break across lines without producing malformed formatting.

The goal is that polymorphic variants “print like variants” when they appear as standalone type definitions (and in similar non-inline contexts), while still behaving well when embedded inside larger type expressions.