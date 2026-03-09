There is a bug in the Reason formatter (`refmt`) when printing `let` bindings whose left-hand side has a type constraint and the pattern includes an alias (`as`). In these cases, the formatted output can drop the necessary parentheses around the aliased pattern, producing syntactically invalid Reason code.

For example, formatting the following valid inputs:

```reason
let x: t = x;
let (x as y): t = x;
let ((x, y) as pair): t = x;
let (Some(x) as opt): t = opt;
let ({url, mode} as target): t = x;
let ({url, mode, protocol} as target): TargetT.Safe.t =
  multiTarget->MultiTargetT.toIgnorableTargetT;
```

currently can produce output like:

```reason
let x: t = x;
let x as y: t = x;
let (x, y) as pair: t = x;
let Some(x) as opt: t = opt;
let { url, mode } as target: t = x;
let { url, mode, protocol } as target: TargetT.Safe.t =
  multiTarget->MultiTargetT.toIgnorableTargetT;
```

This output is wrong because patterns such as `x as y`, `Some(x) as opt`, `{...} as target`, etc. must be wrapped in parentheses when followed by a value-binding type constraint (`: t`), i.e. the correct formatting is `(pattern as alias): t`.

Update the formatter so that whenever a value binding is printed with a type constraint (`let <pattern>: <type> = ...`) and the `<pattern>` contains an alias pattern (`as`), the formatter emits parentheses around the aliased pattern so the result parses correctly.

This should work for a variety of patterns, including:

```reason
let (x as y): t = x;
let (Some(x) as opt): t = opt;
let ({url, mode} as target): t = x;
let (Foo.{url, mode} as target): t = x;
let ([x, y] as listPair): t = value;
let (_ as anyValue): t = value;
```

It must also avoid adding parentheses where they are not needed; for instance, a non-aliased record pattern constrained with a type should remain:

```reason
let { url, mode }: t = x;
```

Finally, formatting must be idempotent: running `refmt` on already-formatted output should yield exactly the same output (no further changes after a second pass).