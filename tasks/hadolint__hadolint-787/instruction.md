Hadolint incorrectly reports rule DL3025 ("Use arguments JSON notation for `CMD` and `ENTRYPOINT` arguments") for valid `CMD`/`ENTRYPOINT` instructions written in exec-form JSON array notation when a long string argument is split across multiple lines using Dockerfile line continuations.

DL3025 should only warn when `CMD` or `ENTRYPOINT` is not using JSON notation (shell form like `CMD something` or `ENTRYPOINT something`). It should not warn when JSON notation is used, including cases where a single string element contains escaped newlines and the JSON array spans multiple Dockerfile lines.

Reproduction example that should NOT produce DL3025 but currently does in affected versions:

```Dockerfile
CMD ["/bin/sh", "-c", \
  "true; \
  true;"]
```

Another example that should also be accepted without DL3025:

```Dockerfile
CMD [ "/bin/sh", "-c", \
      "echo foo && \\
       echo bar" \
    ]
```

Expected behavior: When `CMD` (and similarly `ENTRYPOINT`) is provided in JSON exec form, DL3025 must not be raised even if the JSON array is broken across lines and includes long string elements continued with `\`.

Actual behavior: DL3025 is raised for these multi-line exec-form cases, as if the instruction were not using JSON notation.

Fix DL3025’s detection so it correctly recognizes exec-form JSON notation across line continuations and does not emit a warning for well-formed multi-line JSON arrays.