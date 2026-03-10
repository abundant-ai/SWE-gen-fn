When using the `(sandbox patch_back_source_tree)` mode, Dune turns modifications made inside the sandbox into promotions to the source tree. If a build results in a patch-back diff (i.e., the sandboxed action changed a source dependency or created a new file that would need promotion), Dune intentionally fails the build so the user notices and can run `dune promote`.

Currently, when this patch-back mechanism triggers a failure, the user does not consistently get the unified diff printed to stderr/stdout for the files that differ. This is confusing because the build fails without showing what changed, unlike other Dune workflows where a failing “needs promotion” situation prints a diff.

Fix Dune so that whenever a patch-back from `patch_back_source_tree` would introduce a promotion and the build is failed for that reason, Dune prints the diff(s) for the affected file(s) as part of the failure output.

Concretely:
- If a sandboxed rule depends on a source file `x` and the action modifies it (e.g. writes new contents to `x`), running `dune build` should fail and print a standard unified diff showing the change (with headers like `--- x` and `+++ _build/default/x`, and `@@` hunk markers), and then exit with a non-zero status.
- If a sandboxed action creates a new file (e.g. `y` that didn’t exist in the source tree), running `dune build` should fail and print a diff that represents creating that file (a unified diff that goes from empty to the new contents), and then exit non-zero.
- This diff printing should happen as part of the patch-back failure path (not only when explicitly asking for promotions or when other unrelated diff mechanisms are used), and should be consistent with how Dune prints diffs for other promotion-related failures.

Expected behavior example (shape of output):
If `x` initially contains `blah` and the sandboxed action changes it to `Hello, world!`, `dune build` should emit something like:

```
File "x", line 1, characters 0-0:
--- x
+++ _build/default/x
@@ -1 +1 @@
-blah
+Hello, world!
```

and then exit with status 1. After running `dune promote x`, the source file `x` should contain the new contents.

If a sandboxed action deletes a source dependency (e.g. removes `foo`), the build should fail with an error indicating the file should be deleted, and the promotion mechanism should still allow applying that deletion via `dune promote`; but in cases where the failure is due to patch-back differences, the relevant diff information should be printed as described above.