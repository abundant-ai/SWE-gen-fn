Pattern variable tracking in the typechecker is inconsistent and loses or corrupts variable information across certain pattern forms, especially around nested/compound `=` patterns and repeated refinements. This becomes visible when using variables bound in patterns later in the expression (or when reporting errors), and it also affects how pattern mismatch diagnostics are emitted.

When typechecking patterns, variables bound on either side of `=` should be captured and usable with the refined type implied by the pattern. This should work both in "head-style" pattern lists and in normal sequential code.

Concrete cases that must behave correctly:

```elixir
# variables captured from simple assignment patterns
typecheck!([x = :foo], x) == dynamic(atom([:foo]))
typecheck!([:foo = x], x) == dynamic(atom([:foo]))

# variables captured from a normal assignment expression
typecheck!(
  (
    x = :foo
    x
  )
) == atom([:foo])
```

Refinement across multiple patterns must propagate correctly so that later matches narrow earlier variables:

```elixir
typecheck!([%y{}, %x{}, x = y, x = Point], y) == dynamic(atom([Point]))
```

If the same variable is refined repeatedly, error reporting must not repeatedly overwrite or spam the variable’s “where it came from” information. When a type error is reported for a later expression involving a variable, the diagnostic should still attribute the variable’s type to its original binding context and keep a stable description of that variable’s type provenance.

When a pattern is known to never match, the typechecker should emit the pattern-mismatch diagnostic (for example, "the following pattern will never match"), but it must not “corrupt” variable tracking for values extracted from the pattern. In particular, code like the following should still allow `info` to be accessed afterward with sensible typing, even though the match is impossible:

```elixir
(
  [info | _] = __ENV__.function
  info
)
```

Underscore `_` must not be treated as a tracked variable and must not force evaluation/refinement in a way that produces an incorrect type; for example:

```elixir
typecheck!(_ = raise("oops")) == none()
```

`=` precedence/associativity in patterns must not change variable capture/refinement. Matching through chained `=` should produce the same type for `x` regardless of grouping:

```elixir
uri_type = typecheck!([x = %URI{}], x)

typecheck!(
  (
    x = %URI{} = URI.new!("/")
    x
  )
) == uri_type

typecheck!(
  (
    %URI{} = x = URI.new!("/")
    x
  )
) == uri_type
```

Finally, incompatible chained patterns must be detected and reported as non-matching patterns:

```elixir
typeerror!([x = 123 = "123"], x) == "the following pattern will never match" <> _
```

Fix the variable tracking/refinement logic used during pattern typechecking so that variable bindings are collected deterministically across pattern forms, refinements propagate across related patterns, `_` is ignored, and mismatch diagnostics do not break subsequent variable typing or provenance in error messages.