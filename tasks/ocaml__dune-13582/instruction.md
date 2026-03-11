`dune install` has incorrect/unstable behavior when the install destination path conflicts with an existing filesystem object (file vs directory), and it can also fail to preserve executable permissions for installed shared plugin files (`.cmxs`). This shows up in three main scenarios that should be handled consistently.

1) Installing `.cmxs` artifacts should preserve the executable bit. When a library build produces `foo.cmxs`, after running `dune build @install` the installed copy in the build install tree must be executable, and after running `dune install --prefix <prefix>` the installed `foo.cmxs` under `<prefix>/lib/<pkg>/` must also be executable. Currently, the installed `.cmxs` may lose the executable bit (not `-x`), which breaks tooling expecting to be able to load/execute it.

2) When installing a file to a destination path that already exists as an empty directory, `dune install` should delete that empty directory and proceed with installation. For example, if `<prefix>/lib/foo/foo.a` already exists but is an empty directory, `dune install` should remove it (and print a message indicating it deleted an empty directory) and then write the `foo.a` file.

3) When installing a file to a destination path that already exists as a non-empty directory, `dune install` must refuse to proceed and emit a clear error message instructing the user to delete it manually. For example, if `<prefix>/lib/foo/foo.a/` exists and contains files, installation must fail with the error:

`Error: Please delete non-empty directory <prefix>/lib/foo/foo.a manually.`

Additionally, when the install layout expects a directory but a file exists in its place, `dune install` should fail with a clear `Not a directory` error coming from attempting to access a path under that directory. For example, if `<prefix>/lib/foo` is a file, attempting to install `<prefix>/lib/foo/META` should fail with an error of the form:

`Error: stat(<prefix>/lib/foo/META): Not a directory`

Fix the filesystem/destination checking logic so these behaviors are correct and consistent, including correct permission handling for `.cmxs` installs and correct handling of file-vs-directory conflicts (empty directory replaced automatically, non-empty directory rejected with the exact message above, and file-instead-of-directory producing the `Not a directory` stat error).