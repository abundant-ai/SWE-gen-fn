`refmt` fails to correctly parse and/or print OCaml 4.08 “binding operator” let-bindings (e.g. `let*`, and more generally `let.<op>`) when they appear in a `let`-binding position inside an expression block and are preceded by comments or attributes. In particular, formatting code that contains a binding-operator let statement immediately after a multiline comment (including doc comments like `/** ... */`) can cause `refmt` to crash with an error like `Unclosed "{" ...` instead of producing formatted output.

Reproduction example (Reason syntax):

```reason
let x = {
  /**
   * A doc comment
   */
  let.opt _ = Some("foo");
  None
};
```

Currently, running `refmt --print re` on inputs like the above can either fail with the unclosed-brace parse error, or drop/misplace the comment/attribute association with the binding-operator let statement.

`refmt` should support binding operators written as `let.<op>` (including operator names containing characters that could be confused with comment tokens, such as `/\/` or `/\*`), and it must correctly handle leading attributes and comments attached to these let-bindings. For example, formatting should preserve and correctly place:

- Attributes applied to the binding-operator let statement, e.g.:
  ```reason
  let x = {
    [@foo]
    let.opt _ = Some("foo");
    None;
  };
  ```
  which should format so the attribute remains associated with the `let.opt` binding.

- Doc comments immediately before the binding-operator let statement, without triggering parser errors.

Additionally, printing should be correct for binding-operator names that include special characters. For instance:

```reason
let z = {
  let./\/ a = Some(2);
  let.&/\* b = Some(5);
  a + b;
};
```

The formatted output must keep these operator names intact (including correct escaping/parenthesization where needed) and must remain valid syntax.

Finally, formatting must be idempotent: formatting an input to an output and then formatting that output again should produce exactly the same result, and the formatted output should successfully type-check when compiled via `ocamlc` with `-pp 'refmt --print binary'`.