Package build actions currently support running tool substitutions like %{bin:make}, but do not support the shorthand %{make}. This causes package builds that declare build commands such as:

(run %{make})

to fail during expansion/interpretation of the action because %{make} is not recognized/resolved to an executable.

Update the package build/action expansion logic so that %{make} is accepted as a valid substitution and resolves to the system "make" executable in the same way that (run %{bin:make}) does. After the change, a package that provides a Makefile in its source and uses (build (run %{make})) should successfully execute make and produce the expected output from the Makefile (e.g., running the default target).

Expected behavior:
- %{make} expands to an executable invocation of make.
- (run %{make}) successfully runs make in the package build context.
- Behavior should be consistent with other tool shorthands (if any exist) and with %{bin:make} resolution rules (e.g., finding make on PATH).

Actual behavior (current):
- %{make} is rejected as an unknown/unsupported variable or fails to resolve to an executable, causing the package build to error before make is run.