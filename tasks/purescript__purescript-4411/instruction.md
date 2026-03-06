When the compiler reports a `TypesDoNotUnify` error caused by a type mismatch inside record/row unification, the error message currently only shows the mismatched types (e.g. `Int` vs `String`) and the broader context, but it does not indicate which record field (row label) the mismatch occurred under. This makes it hard to locate the real cause in large records or deeply nested records.

Update the `TypesDoNotUnify` diagnostic so that when the type mismatch arises while unifying two records/rows and the mismatch corresponds to a specific row label, the error output includes one or more additional context lines indicating the label(s) being matched at the point of failure.

For example, given:

```purescript
a :: { field :: Int }
a = { field: 1 }

b :: { field :: String }
b = a
```

the error should still report it “Could not match type Int with type String”, and it must also include a line like:

`while matching label field`

before the subsequent “while checking …” context.

For nested records, the error should include the full nesting path as separate context lines, starting from the innermost mismatching label outward. For example, given records of types `{ a :: { b :: { c :: Int } } }` and `{ a :: { b :: { c :: String } } }`, the error should include:

`while matching label c`
`while matching label b`
`while matching label a`

in addition to the standard type mismatch message.

Do not add these “while matching label …” context lines for type mismatches that occur immediately in an expression/type annotation check where no row-unification label context is involved (for example, assigning a string literal to a field annotated as `Int` directly in a record literal should continue to produce the usual `TypesDoNotUnify` message without any added “matching label …” lines).

The goal is that `TypesDoNotUnify` errors produced by record/row unification precisely identify the field path where the mismatch occurs, improving usability for large and nested records, while avoiding making non-row type mismatch errors noisier.