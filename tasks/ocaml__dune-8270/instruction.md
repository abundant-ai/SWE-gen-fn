Building/installing Dune can fail with a permission error on some Linux filesystems (notably ecryptfs) when Dune tries to copy files using the optimized `sendfile`-based implementation and then falls back to a portable copy after `sendfile` fails.

A common failure looks like:

```
Error: _build/default/bin/dune.exe: Permission denied
```

This can happen during `opam upgrade` while building Dune itself, but it can also be reproduced in a normal workspace by creating a rule that copies a file and running a build where `sendfile` is forced to fail (for example by using `strace` to inject an error like `sendfile:error=EINVAL`). When `sendfile` fails, Dune is expected to fall back to the portable copying implementation and still complete the copy/install successfully.

Currently, when `sendfile` fails after having already created the destination file, the fallback path may attempt to open/truncate/overwrite the existing destination in a way that can produce `EACCES` (permission denied), particularly when the destination already exists and/or has restrictive permissions due to how it was created during the failed fast-path attempt.

Fix the copy implementation so that if the `sendfile` fast path fails and Dune falls back to the portable copy, the destination path is put into a safe state before the fallback begins. In particular, ensure the partially-created destination file from the failed `sendfile` attempt does not block the fallback (e.g., it must be adequately removed/unlinked first), so the fallback copy succeeds and produces the correct destination contents.

After the fix:
- A build that triggers `sendfile` failure (e.g., injected `EINVAL`) must still succeed by using the fallback.
- The copy rule should reliably produce the destination file with the same contents as the source.
- The behavior must avoid raising `Unix.Unix_error(Unix.EACCES, ...)` / “Permission denied” in this scenario.

Also ensure any resource cleanup around the fast-path attempt is robust so that failures do not leak file descriptors or leave the system in a bad state (the fallback should run even when the fast path raises).