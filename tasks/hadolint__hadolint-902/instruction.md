Hadolint is incorrectly rejecting valid Dockerfiles that use `EXPOSE` with a port range containing environment-variable interpolation, especially in Windows-style Dockerfiles that use the backtick escape character for line continuations.

When linting a Dockerfile containing an `EXPOSE` like:

```Dockerfile
# escape=`
...
ENV `
APP_PORT=4330 `
APP_PORT_MAX=4340

EXPOSE `
${APP_PORT}/tcp `
${APP_PORT}-${APP_PORT_MAX}/tcp
```

hadolint fails while parsing the `EXPOSE` instruction with an error similar to:

```
unexpected '$' expecting '`', a new line followed by the next instruction, or the variable name
```

Docker itself accepts `${APP_PORT}-${APP_PORT_MAX}/tcp`, so hadolint should also accept this syntax and proceed to linting.

In addition, the DL3011 rule (“Valid UNIX ports range from 0 to 65535”) must correctly validate port ranges when the `EXPOSE` instruction includes ranges and variables, based on the parsed AST for `EXPOSE`.

Required behavior:
- `EXPOSE 40000-60000/tcp` should be accepted by the parser and should not trigger DL3011.
- `EXPOSE 40000-80000/tcp` should be accepted by the parser but should trigger DL3011 because `80000` is out of range.
- Variable-based ports should not be rejected just because they are variables:
  - `EXPOSE ${FOOBAR}` should not trigger DL3011.
  - `EXPOSE 40000-${FOOBAR}` should not trigger DL3011.
- The Windows escape/backtick multi-line form of `EXPOSE` must allow a port range token like `${APP_PORT}-${APP_PORT_MAX}/tcp` without producing a parse error.

The fix should update DL3011’s AST handling so it correctly recognizes and validates port ranges (including those involving variables) in `EXPOSE` instructions under the current Dockerfile AST representation.