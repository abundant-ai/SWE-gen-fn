Reason’s formatter/printer currently drops attributes that are attached to a module expression, causing source information to be lost after formatting.

For example, formatting the following code:

```reason
module Foo = [@someattr]{
  type t = string;
};
```

removes the attribute so the formatted output no longer contains `[@someattr]` on the module expression.

This should be fixed so that attributes applied to module expressions are preserved and printed in the correct location when running the formatter (e.g., `refmt`). After the change, formatting and re-formatting code with module-expression attributes must round-trip without losing any attributes.

The fix must handle module bindings where the right-hand side is a module structure expression (braced module body) as well as other module expression forms that can legally carry attributes, ensuring attributes are not discarded during AST-to-document printing.