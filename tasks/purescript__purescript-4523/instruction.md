The PureScript parser currently accepts typed variable binders (including `@` visible type application binders) in a type class head, but class heads should only allow plain type variables.

Reproduction:
```purescript
module Main where

class Foo @a
```

Actual behavior: the module parses successfully, allowing `@a` in the class head.

Expected behavior: this must be a parse error (consistent with how `data` declarations behave), because the compiler implicitly introduces visible binders for class variables and therefore `@` binders are not permitted in the class head syntax.

When parsing a class declaration head (the portion immediately after `class <Name>`), the parser should reject `@` binders and report an error indicating an unexpected `@` token. The resulting error should be an `ErrorParsingModule`-style parse failure, and the diagnostic should include text like:

`Unable to parse module: Unexpected token '@'`

Ensure the class head parser uses the “plain” type variable binder form (i.e., does not accept `typeVarBinding` that permits `@` binders) so that `class Foo a` remains valid but `class Foo @a` is rejected.