Hadolint’s rules DL3032 and DL3040 incorrectly warn that cache cleanup is missing after package installation when the Dockerfile cleans the yum/dnf cache by deleting the cache directory directly instead of running the package manager’s clean command.

Currently, DL3040 reports a warning after `dnf`/`microdnf` commands unless it sees `dnf clean all` / `microdnf clean all`. This produces a false-positive for Dockerfiles that legitimately clean the cache using a command like `rm -rf /var/cache/yum/*` (or equivalent) after `dnf install`/`microdnf install`.

Similarly, DL3032 reports a warning after `yum` commands unless it sees `yum clean all`, and it also should treat explicit removal of the yum cache directory as an acceptable cleanup.

Reproduction example (should be accepted without warnings from the relevant rule):

```Dockerfile
RUN dnf install -y mariadb-10.4 \
  && rm -rf /var/cache/yum/*
```

and for yum:

```Dockerfile
RUN yum install -y mariadb-10.4 \
  && rm -rf /var/cache/yum/*
```

Expected behavior:
- DL3040 should not trigger if a `dnf` or `microdnf` install/update is followed in the same RUN by explicitly deleting the yum cache directory (e.g. `rm -rf /var/cache/yum/*`), in addition to the existing accepted `dnf clean all` / `microdnf clean all` forms.
- DL3032 should not trigger if a `yum` install/update is followed in the same RUN by explicitly deleting the yum cache directory (e.g. `rm -rf /var/cache/yum/*`), in addition to the existing accepted `yum clean all` form.
- Cases without any cleanup after the install/update should still trigger the corresponding rule.

Actual behavior:
- DL3040 (and DL3032 for yum) warns about a missing clean step even when the cache is cleaned via `rm -rf /var/cache/yum/*`.