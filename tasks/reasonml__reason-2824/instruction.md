In the Reason formatter (refmt), record field punning and JSX prop punning are applied too aggressively when the value expression is annotated with an attribute. This causes attributes to effectively disappear from the formatted output whenever the field/prop name matches the variable name (i.e., the case where punning would normally be allowed).

For example, formatting this JSX:

```reason
<button onFocus={onFocus} onClick={[@foo] onClick} />
```

currently produces output equivalent to:

```reason
<button onFocus onClick />
```

which is incorrect because it drops the `[@foo]` attribute and changes the meaning/AST. The expected formatted output must preserve the attribute and therefore must not pun the prop in this case, e.g.:

```reason
<button onFocus onClick={[@foo] onClick} />
```

The same bug occurs for record literals/record expressions when a field value is attribute-annotated and the field name matches the identifier being used. For instance, formatting:

```reason
let foo = {a: [@hey] a};
let foo = {a: a, b: b, c: c, d: [@hey] d};
```

currently rewrites the attribute-annotated fields into punned fields (or otherwise removes the explicit assignment), producing output like:

```reason
let foo = {a};
let foo = {
  a,
  b,
  c,
  d,
};
```

This is incorrect because the attribute on the value expression is lost. The formatter should instead keep the explicit `field: expr` form for any record field or JSX prop whose value expression carries attributes, even if the expression is otherwise a simple identifier identical to the field/prop name.

After the fix, formatting should still pun normal cases like `{a: a}` into `{a}` and `<button onFocus={onFocus} />` into `<button onFocus />`, but it must not pun when doing so would remove an attribute. Formatting should be idempotent: re-formatting the formatter’s output should not change it again.