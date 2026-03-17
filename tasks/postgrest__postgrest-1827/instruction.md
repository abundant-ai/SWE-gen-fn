Several developer/CI helper commands in the nix-based development environment are currently unreliable and inconsistent, especially in “pure” nix shells and when running coverage/tests.

1) `postgrest-dump-schema` fails when run under `nix-shell --pure` because `yq` depends on `jq` being available at runtime. In a pure environment, `jq` is not on `PATH`, so schema dumping breaks. Running `postgrest-dump-schema` inside `nix-shell --pure` should work without requiring users to manually install or expose `jq`.

2) `postgrest-coverage` triggers an unnecessary rebuild during the test run because the build step and the test step use mismatched flags/targets (e.g., one side enables tests while the other doesn’t). This causes the test invocation to reconfigure/rebuild instead of immediately running. The coverage workflow should be consistent so that once the coverage build step completes, the subsequent test/coverage execution does not perform an extra rebuild just due to differing flags or implicit targets.

3) Temporary-directory handling used by helper scripts (notably the temp database runner invoked as `with_tmp_db COMMAND`) is currently inconvenient for CI debugging. Temporary directories are created with generic names in arbitrary locations, making it hard to collect them as CI artifacts. Temp directories should be created under a predictable common root such as `/tmp/postgrest/...`, and each individual temp directory should be prefixed with the name of the shell script/command being run (rather than a generic `tmp.xxxx`). When `KEEP_TMP` is set, the directory should be preserved and its location clearly reported; when not set, cleanup should still happen reliably on exit and signals.

4) The `with_tmp_db` helper should behave like a “checked” shell script (i.e., run with strict error handling and consistent packaging/execution expectations) so it works reliably in the nix development environment and in CI/Docker contexts. Invoking `with_tmp_db` with no command should print a helpful usage message and exit non-zero; invoking it with a command should start a temporary Postgres instance, set `PGRST_DB_URI` (and related env like `PGRST_DB_SCHEMAS` and `PGRST_DB_ANON_ROLE`) for that command, load fixtures, run the command, then stop Postgres and clean up (or keep the directory if `KEEP_TMP` is set).

Overall, after these fixes, common workflows like:

- Running schema dump tools in `nix-shell --pure`
- Running `postgrest-coverage` without a redundant rebuild
- Running `with_tmp_db cabal v2-test` (or equivalent) while getting predictable temp directory locations for debugging

should work consistently both locally and in CI.