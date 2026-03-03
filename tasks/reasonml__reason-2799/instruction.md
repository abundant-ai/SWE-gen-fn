Formatting OCaml callback functions that contain a sequence (e.g., a `let ... in` followed by another expression) is not preserved correctly when converting back into Reason syntax. When `refmt` converts OCaml code where a callback body is a sequence, the resulting Reason output can omit the required block braces `{ ... }` around the callback body, producing invalid or semantically incorrect Reason code.

Reproduction example (OCaml input):

```ocaml
onEvent "/echo" (fun request ->
  let request_stream = get_body_stream request in
  stream
    ~headers:[ ("Content-Type", "application/octet-stream") ]
    (fun response_stream -> Js.log response_stream))
```

Current (incorrect) Reason output produced by `refmt`:

```reason
onEvent("/echo", request =>
  let request_stream = get_body_stream(request);
  stream(
    ~headers=[("Content-Type", "application/octet-stream")], response_stream =>
    Js.log(response_stream)
  );
);
```

This is missing the braces around the callback body even though it contains multiple statements. The expected (correct) Reason output must wrap the callback body in a block:

```reason
onEvent("/echo", request => {
  let request_stream = get_body_stream(request);
  stream(
    ~headers=[("Content-Type", "application/octet-stream")], response_stream =>
    Js.log(response_stream)
  );
});
```

The same problem appears in simpler cases like formatting an OCaml anonymous function passed as an argument where the function body is a sequence:

```ocaml
ignore (fun y ->
  let y = 4 in
  y)
```

When formatted to Reason, the callback must be emitted as `y => { ... }` (with braces) and the output should be stable under round-tripping: formatting the produced Reason and formatting it again (or converting it back and forth) should yield identical results (idempotent formatting).

Fix `refmt` so that when printing a callback/arrow function translated from OCaml whose body is a sequence (multiple statements / `let ...` followed by another expression), it always prints a braced block `{ ... }` in Reason. Ensure that converting `.ml` to Reason and then formatting the produced Reason back again preserves the exact same Reason output (no missing braces, no structural changes).