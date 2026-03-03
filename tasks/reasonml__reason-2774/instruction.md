`refmt` currently prints some `lazy` patterns using deprecated v2 syntax, which can change the meaning/shape of code and contradict expected v3 formatting.

Reproduction: formatting a binding or pattern-match that destructures a lazy value with parentheses, such as:

```reason
let (lazy(value)) = myLazyValue;
```

After running `refmt --print re`, the output is incorrectly rewritten to the v2-style form:

```reason
let lazy value = myLazyValue;
```

This is wrong because the `lazy` destructuring is a pattern and should remain a `lazy(<pattern>)` form, not be printed as `lazy <ident>`.

Expected behavior: when formatting any `lazy` pattern, `refmt` must always print it with explicit parentheses around the inner pattern so it stays unambiguously a pattern and remains in v3 syntax. For example, these should round-trip and remain stable (idempotent) under repeated formatting:

```reason
let lazy(thisIsActuallyAPatternMatch) = lazy(200);
let (lazy((Box(i))), x) = (lazy(Box(200)), 100);
let lazy((x: int)) = 10;
let lazy([]) = 10;
let lazy(true) = 10;
let lazy(#x) = 10;
let lazy(`Variant) = 10;
let lazy('0' .. '9') = 10;
let lazy((lazy(true))) = 10;
let operateOnLazyValue = (lazy({myRecordField})) => myRecordField + myRecordField;
```

In all of the above, the formatted output should keep the `lazy(<pattern>)` structure and, when needed for precedence, wrap the inner pattern in parentheses (including nested patterns like `Box(i)` and typed patterns like `(x: int)`), so that re-formatting the formatter output produces identical code (idempotency) and never emits `let lazy value = ...` for these cases.

Actual behavior: at least some of these cases are formatted without parentheses (or rewritten into `lazy value`), producing legacy v2 syntax and breaking the expected formatting output.

Fix `refmt` so that formatting a `lazy` pattern always emits `lazy(<pattern>)` with appropriate parentheses, and the formatted output type-checks and remains idempotent when formatted again.