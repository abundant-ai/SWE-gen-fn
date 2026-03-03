The Reason formatter (`refmt`) prints functor declarations and applications with unnecessary or incorrect parentheses/braces in cases involving empty functor arguments. This causes formatted output to change meaningfully and produces noisy, non-idiomatic results.

Given code like:

```reason
module Lola = () => {
  let a = 33;
};

module L = Lola();
```

`refmt` currently rewrites it into a more verbose form that introduces extra syntax:

```reason
module Lola = (()) => {
  let a = 33;
};

module L =
  Lola({});
```

This is undesirable for two reasons:
1) The functor declaration gains an extra set of parentheses around the unit argument, turning `() =>` into `(()) =>`.
2) The functor application `Lola()` is rewritten as `Lola({})`, switching from unit `()` to an empty module expression `{}`.

Update `refmt`’s printing of functor types/expressions so that:
- An empty functor argument written as `()` remains `()` when formatted (no introduction of `(())`).
- Instantiating a functor with a unit argument stays `F()` rather than being rewritten to `F({})`.
- Parentheses around functor usage are minimized so that already-simple functor expressions do not gain additional wrapping.

After the change, formatting the original snippet should preserve the unit functor syntax:

```reason
module Lola = () => {
  let a = 33;
};

module L = Lola();
```

and similar functor usages in larger module-related code should not gain redundant parentheses or be rewritten to use `{}` when the source uses `()`.