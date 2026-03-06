When running hadolint with the JSON formatter on a Dockerfile that fails to parse, the emitted JSON currently contains an incorrect `message` field. Instead of a clean parse error message, the `message` value is polluted with pretty-printed source snippets, caret markers, and extra newlines.

For example, running:

```bash
docker run --rm -i hadolint/hadolint hadolint -f json - < <(echo 'RUNNN')
```

Currently produces a JSON `message` similar to:

```
/dev/stdin:1:4:
  |
1 | RUNNN
  |    ^
missing whitespace
```

Expected behavior: the JSON formatter must output a clean `message` string containing only the actual parse error text, e.g. `missing whitespace`, without any file/line decorations, source previews, caret markers, or embedded leading/trailing newlines.

Implement/adjust `errorMessage` so that, given a `ParseErrorBundle` from parsing a Dockerfile, it returns only the human-readable error message text (for the `RUNNN` input, exactly `missing whitespace`). The JSON formatter must use this clean error text for the `message` field when reporting errors that prevent rule application (such as parsing errors).

After the change, formatting a parse error as JSON for a Dockerfile consisting of `RUNNN` should yield an object where `code` is `DL1000`, and `message` is exactly `missing whitespace` (with correct line/column metadata preserved separately, rather than embedded into `message`).