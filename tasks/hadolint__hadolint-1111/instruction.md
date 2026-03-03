Hadolint’s new rule DL3062 (“Pin versions in go install”) is incorrectly flagging some valid uses of `go run`. In particular, when a Dockerfile uses `go run` to execute a local Go source file that is part of the build context (for example `RUN go run /path/to/file.go <args>`), DL3062 currently reports a warning like:

"Pin versions in go. Instead of `go install <package>` use `go install <package>@<version>`"

This is overly strict because a local `.go` file is already pinned by the repository revision, and it is not a module path that supports `@<version>`.

DL3062 should continue to warn when `go install`, `go get`, or `go run` is invoked with a module/package argument that is not version-pinned (no `@...`) or is effectively unpinned (`@latest`). It should not warn when `go run` targets a local file (e.g., any argument that clearly denotes a file path such as ending in `.go`, including absolute or relative paths).

Expected behavior:
- `RUN go install example.com/pkg` is flagged by DL3062.
- `RUN go install example.com/pkg@latest` is flagged by DL3062.
- `RUN go install example.com/pkg@v1.2.3` is not flagged.
- `RUN go get example.com/pkg` is flagged.
- `RUN go run example.com/pkg` is flagged.
- `RUN go run example.com/pkg@v1.2.3` is not flagged.
- `RUN go run /some/path/file.go` (and similar local-file invocations) is not flagged.

Actual behavior:
- DL3062 flags `go run` even when it is executing a specific local `.go` file, and the warning message suggests using `go install <package>@<version>`, which is not applicable to local-file `go run` usage.

Update DL3062’s logic so it distinguishes between `go run` with module/package arguments (which must be version pinned) and `go run` with local `.go` file arguments (which should be allowed without `@<version>`).