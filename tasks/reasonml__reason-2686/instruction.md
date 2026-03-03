`refmt` currently prints type annotations on anonymous functions in a way that moves the return type to a type-ascription on the function body, rather than keeping the return type immediately after the argument list.

For example, when formatting an anonymous function with an explicit return type like:

```reason
(x: int): int => some_large_computation;
```

`refmt` rewrites it to the less desirable form:

```reason
(x: int) => (some_large_computation: int);
```

This behavior should be changed so that `refmt` preserves/prints the return type on the function itself (after the parameters and before `=>`) whenever an anonymous function has an explicit return type.

The issue affects both block-bodied and expression-bodied anonymous functions, including cases where the function is passed as an argument, defined inside other expressions, or preceded by attributes. The formatting should also handle long parameter lists gracefully (including line-breaking) while still keeping the `: <returnType>` attached to the function signature rather than converting it into a body ascription.

Concretely, these should format with the return type after the arguments:

```reason
(acc, curr): string => {
  let x = 1;
  string_of_int(curr);
}
```

and for expression bodies:

```reason
(): string => "foo";
```

rather than emitting body-ascribed forms like `() => ("foo": string)`.

After the change, formatting should consistently prefer `args: returnType => body` for anonymous functions with an explicit return type, without introducing a body type annotation as a substitute.