Running PostgREST with the `--version` (or `-v`) CLI flag currently fails with an “Invalid option `--version`” style error instead of printing version information. The CLI should accept `-v` and `--version` as valid options and immediately print a single line of version information, then exit successfully.

Reproduction:

```bash
postgrest --version
postgrest -v
```

Expected behavior:
- Both invocations should succeed (exit code 0).
- Output should be a single human-readable line containing the program name and version, and may include build metadata such as a git commit hash, e.g.:

```
PostgREST 11.1.0 (e752224)
```

Actual behavior:
- The CLI rejects `--version` / `-v` as an invalid option and exits with an error.

The change should not break existing CLI flags such as `--help`/`-h`, `--example`/`-e`, `--dump-config`, and `--dump-schema`. When `--version` is provided, it should not require any configuration or environment variables to be present; it should print the version and exit without attempting normal startup.