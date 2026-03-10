When using hledger’s `include` directive to load another journal file, directives inside the included file (notably the `D` default commodity/format directive) are not consistently honored. This causes amounts in the parent journal to be rendered/combined using multiple “currencies” even though the included file sets a default display commodity/format.

Reproduction example:

1) Create a main journal that includes another journal:

```hledger
include include.journal

2026-07-01 Test transaction #1
    assets:bank    £1000
    expenses:foo

2026-07-01 Test transaction #2
    assets:bank     1000
    expenses:bar
```

2) Create `include.journal` with a `D` directive:

```hledger
D £1,000.00

2025-07-01 Test transaction from include.journal
    assets:bank  500
    expenses:foo
```

3) Run a report such as:

```sh
hledger -f test.journal bs
```

Expected behavior: the `D £1,000.00` directive found in the included file should be applied while processing the overall journal so that amounts are normalized/formatted consistently (eg the balance sheet should show a single formatted £ amount like “£2,000.00” rather than mixing “1000” and “£1000”). Included file content (transactions and directives) should be honored in the same way as if that content were written inline in the parent journal at the include position.

Actual behavior: the included transaction is included, but the included file’s `D` directive is ignored, and reports show mixed display/commodity formatting (eg separate totals like `1000, £1,500.00`).

Additionally, `include` file matching and error handling has several usability problems that should be addressed together:

- `include` should support glob patterns robustly and predictably. Patterns should be able to match multiple files and preserve a deterministic include order.
- A leading `~` in an include path should expand to `$HOME`.
- Invalid `include` usage should produce clear errors:
  - `include` with no argument should fail with an argument error (message like “include needs an argument”).
  - Including a nonexistent file or a directory should fail with a “No files were matched” style error.
  - Invalid glob patterns (eg `include [.journal`) should fail with an “Invalid glob” style error.
  - Patterns with three or more consecutive `*` (eg `include ***`) should be rejected as invalid.
- Include cycle detection must work reliably:
  - Including the current file literally should error as a cycle.
  - Cycles across multiple files should error as a cycle.
  - If a glob pattern expands to include the current file, that should not cause failure; the current file should be ignored in glob results (at least once) so that harmless self-matches don’t create false cycle errors.

Finally, glob matching semantics used by `include` should be improved:

- `**` should be usable without a following slash to also match the start of a filename (so patterns like `*/**.j` behave like `*/**/*.j`).
- Glob-matched paths should ignore dot directories (directories beginning with `.`) to avoid surprising matches inside hidden directories.
- If the new dot-directory exclusion breaks prior behavior, there should be a compatibility option `--old-glob` that restores the previous glob behavior.

Implement the above so that `include` behaves as a reliable way to compose journals: included files contribute all their directives and entries as expected, globbing is more ergonomic, and failure modes provide consistent, line-accurate, user-readable error messages. Also add/adjust debug output for `include` processing at higher verbosity (notably around levels 6–7) so users can understand what files were matched and why particular includes were ignored or rejected.