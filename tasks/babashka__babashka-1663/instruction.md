When a babashka script is invoked via a symlink, babashka currently looks for an adjacent bb.edn relative to the symlink path rather than the real (resolved) script path. This causes configuration next to the actual target script to be ignored.

Reproduction example:
- Have a real script file at /real/dir/script.clj and a bb.edn file in /real/dir/bb.edn.
- Create a symlink /link/dir/script.clj -> /real/dir/script.clj.
- Run babashka using the symlink path: bb /link/dir/script.clj.

Expected behavior: babashka should resolve the symlink to its real target location and then search for bb.edn adjacent to the resolved script (so /real/dir/bb.edn is loaded). This should affect dependency resolution and tasks in the same way as when the script is invoked directly via /real/dir/script.clj.

Actual behavior: the bb.edn next to the resolved target is ignored when invoked via symlink, so dependencies/tasks/configuration in /real/dir/bb.edn are not applied.

Fix this so that script execution and bb.edn loading behave identically whether the script is invoked directly or through a symlink. Ensure this behavior also holds for cases where bb.edn affects classpath/deps resolution and task execution (e.g., running tasks from bb.edn, requiring deps specified in bb.edn).