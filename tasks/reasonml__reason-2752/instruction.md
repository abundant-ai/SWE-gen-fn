On OCaml 5.2, invoking `rtop` no longer reliably loads/uses the Reason integration with `utop`, causing piped input to fail to evaluate as Reason code (or to error before the Reason plugin runs). This breaks common usage like piping code into `rtop` in non-interactive contexts.

Reproduction examples:

1) Running:

```sh
echo "let f = a => a;" | rtop
```

should evaluate the Reason snippet and print a value binding that includes:

```
let f: 'a => 'a = <fun>;
```

but on OCaml 5.2 it does not produce the expected binding output (e.g., it fails early, doesn’t run the Reason toplevel integration, or behaves as if the input is not being handled by the Reason-enabled `utop`).

2) Running:

```sh
echo "let f = (a) => 1 + \"hi\";" | rtop
```

should report a type error containing the message substring:

```
This expression has type string but an expression was expected of type
```

but instead the error is missing, different, or `rtop` exits without producing the expected diagnostic.

Fix `rtop` on OCaml 5.2 so that when `rtop` reads from stdin (e.g., piped input), it still correctly invokes the Reason-enabled `utop` session and produces the expected evaluation output and type-error diagnostics for Reason code. The behavior should work without relying on `utop -stdin` if that mode bypasses or pre-processes input in a way that prevents the Reason plugin from running.