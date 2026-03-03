Hadolint’s rule DL3014 (“Use the `-y` switch to avoid manual input `apt-get -y install <package>`”) incorrectly reports a warning for some `apt-get` invocations that already imply non-interactive behavior.

When linting a Dockerfile containing a command like:

```Dockerfile
FROM debian:stable-slim
RUN apt-get update && apt-get install --quiet --quiet sl
```

hadolint currently emits:

```
DL3014 warning: Use the `-y` switch to avoid manual input `apt-get -y install <package>`
```

This is a false positive because `apt-get`’s quietness flag increases in level when repeated; at quiet level 2 (e.g., `-qq` or `--quiet --quiet`), `apt-get` implies `assume-yes` (equivalent to `-y`). DL3014 should therefore NOT warn when quiet level 2 has been configured via command-line options.

Update DL3014’s detection of “auto-yes already enabled” so that it treats the following as satisfying the `-y` requirement (and does not report DL3014):

- Explicit yes flags anywhere in the command: `-y`, `--yes`, `--assume-yes` (including combinations like `-yq`)
- Quiet level 2 set via any of these forms: `-qq`, `-q -q`, `-q=2`, and `--quiet --quiet`

At the same time, DL3014 should continue to warn when `apt-get install` lacks both explicit yes flags and an effective quiet level 2, including cases like `-q` or a single `--quiet`.

This should apply consistently for both regular `RUN apt-get ...` and `ONBUILD RUN apt-get ...` instructions.