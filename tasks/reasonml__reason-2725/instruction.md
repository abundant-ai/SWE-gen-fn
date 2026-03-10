`refmt` incorrectly prints record destructuring patterns that include a type constraint on a subpattern, dropping required parentheses and producing invalid syntax.

Repro:

Input code:
```reason
let {foo: (_: int)} = 2;
```

Current `refmt` output becomes:
```reason
let {foo: _: int} = 2;
```
This output is not equivalent and is invalid/incorrect because the type constraint `: int` is no longer attached to the parenthesized subpattern `(_ : int)`; instead it gets printed as if it were annotating the record field binding directly.

The same parenthesis-dropping bug also occurs when the same kind of record constraint pattern appears inside `switch` expressions (e.g., switching on a value and matching a record pattern that contains `foo: (_: int)`), and generally anywhere a record field pattern contains a constrained subpattern.

`refmt` should preserve or reintroduce the parentheses required to keep the type constraint bound to the inner pattern. After formatting, the example above must remain valid and must keep the structure:
```reason
let {foo: (_: int)} = 2;
```

Ensure formatting is stable (running `refmt` repeatedly should not change the output further) and that the fix applies consistently in both `let` destructuring and `switch` pattern contexts.