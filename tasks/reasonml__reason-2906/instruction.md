When formatting Reason/OCaml code that defines a function with a type constraint in the body, refmt can get stuck in infinite recursion on OCaml 4.14 due to how the constraint is represented in the parsed AST.

In OCaml 4.14 with ppxlib, an expression like:

```ocaml
let f x = (x : int)
```

is represented as a function expression (`Pexp_function`) where the type constraint is attached to the function node itself (e.g. a `Pconstraint`/coercion associated with the function), rather than being represented as a `Pexp_constraint` (or `Pexp_coerce`) wrapping only the body expression.

The formatter’s function-decomposition logic in `curriedPatternsAndReturnVal` incorrectly treats the entire constrained `Pexp_function` as the “return value” when such a constraint is present. The printer then tries to print that “return value” by re-processing the same function expression again, which results in infinite recursion (hang/stack overflow) instead of producing formatted output.

Update `curriedPatternsAndReturnVal` so that when a function node carries a type constraint/coercion, it still returns the *actual body expression* as the return value, and re-attaches the constraint by wrapping that body in a `Pexp_constraint` or `Pexp_coerce` expression (as appropriate). This must allow the printer to proceed normally without re-visiting the same `Pexp_function` node.

After the fix, formatting should succeed (no recursion/hang) and produce stable output for these cases:

- `let f x = (x : int)` formats to `let f = (x): int => x;`
- `let f x = (x : Foo.bar)` formats to `let f = (x): Foo.bar => x;`
- `let f x y = (x + y : int)` formats to `let f = (x, y): int => x + y;`
- `let f x = (x : int -> int)` formats to `let f = (x): (int => int) => x;`

Re-formatting the produced output should be idempotent (running refmt again yields identical output).