When formatting Reason code with `refmt`, extension expressions (`Pexp_extension`) are not printed consistently depending on where they appear (top-level vs inside a sequence/block), especially when the extension payload is an application expression and/or contains comments. This leads to surprising indentation and line-breaking differences for the same extension form, and in some cases comment placement/association looks wrong.

The formatter should print extension expressions consistently regardless of whether they are inside a sequence (`{ ...; ...; }`) or standalone.

Reproduction examples (current problematic behavior is that these formats differ between standalone and in-sequence cases):

1) Extension with an apply payload should stay on one line when simple:

```reason
[%defer cleanup()];
```

2) Extension whose payload contains a comment should break and indent in a stable way, keeping the comment attached to the payload expression and not altering indentation when the extension occurs inside a sequence:

```reason
[%defer
  /* 2. comment attached to expr in extension */
  cleanup()
];
```

3) The same rules must apply when the extension is inside a sequence/block, preserving surrounding comment attachments:

```reason
let () = {
  /* random let binding */
  let x = 1;
  /* 1. comment attached to extension */
  [%defer cleanup()];
  /* 3. comment attached to next expr */
  something_else();
};
```

and when the extension payload has an internal comment:

```reason
let () = {
  /* random let binding */
  let x = 1;
  /* 1. comment attached to extension */
  [%defer
   /* 2. comment attached to expr in extension */
   cleanup()
  ];
  /* 3. comment attached to next expr */
  something_else();
};
```

Expected behavior: `refmt` should produce stable, consistent printing for `Pexp_extension` in all these contexts, using the same indentation/line-breaking rules whether the extension occurs at the top level or nested inside sequences, and preserving comment attachment so that comments immediately preceding an extension remain associated with the extension, and comments inside the extension remain associated with the payload expression.

Actual behavior: extensions inside sequences are formatted differently from standalone equivalents (notably indentation and layout of the `[%ext ...]` form), and comment layout can differ in a way that suggests the extension/sequence context is influencing formatting incorrectly.