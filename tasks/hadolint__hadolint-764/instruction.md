Hadolint’s dnf-related rules do not currently recognize `microdnf`, which is a slimmed-down dnf used in RedHat UBI minimal images. As a result, Dockerfiles using `microdnf` can bypass the same best-practice checks that are enforced for `dnf`.

When linting a Dockerfile that uses `microdnf` in `RUN` (and in `ONBUILD RUN`) commands, Hadolint should emit the same warnings as it would for equivalent `dnf` usage for the following rules:

1) DL3038: Missing non-interactive flag
If a command installs packages using `dnf install ...` without `-y`, DL3038 warns. The same must happen for `microdnf install ...` when `-y` is missing.

Examples that should trigger DL3038:
- `RUN dnf install httpd-2.4.24 && dnf clean all`
- `RUN microdnf install httpd-2.4.24 && microdnf clean all`
- `ONBUILD RUN microdnf install httpd-2.4.24 && microdnf clean all`

Examples that should NOT trigger DL3038:
- `RUN dnf install -y httpd-2.4.24 && dnf clean all`
- `RUN microdnf install -y httpd-2.4.24 && microdnf clean all`
- Commands for other binaries (e.g. `notdnf`) must not be matched.

2) DL3040: Missing cleanup
If `dnf install -y ...` is used without a subsequent `dnf clean all` in the same shell command chain, DL3040 warns. The same must apply to `microdnf`: `microdnf install -y ...` must be followed by `microdnf clean all`.

Examples that should trigger DL3040:
- `RUN dnf install -y mariadb-10.4`
- `RUN microdnf install -y mariadb-10.4`
- `ONBUILD RUN dnf install -y mariadb-10.4 && microdnf clean all` (cleanup for a different tool must not satisfy the rule)

Examples that should NOT trigger DL3040:
- `RUN dnf install -y mariadb-10.4 && dnf clean all`
- `RUN microdnf install -y mariadb-10.4 && microdnf clean all`
- Commands for other binaries (e.g. `notdnf`) must not be matched.

3) DL3041: Missing version pinning
If `dnf install -y <package>` is used without pinning a version (e.g. `tomcat` rather than `tomcat-9.0.1`), DL3041 warns. The same must apply for `microdnf install -y <package>`.

This also applies to module installs:
- `dnf module install -y tomcat` should warn (unversioned)
- `dnf module install -y tomcat:9` should not warn (versioned)
The same behavior must apply to `microdnf module install ...`.

Examples that should trigger DL3041:
- `RUN dnf install -y tomcat && dnf clean all`
- `RUN microdnf install -y tomcat && microdnf clean all`
- `RUN dnf module install -y tomcat && dnf clean all`
- `RUN microdnf module install -y tomcat && microdnf clean all`

Examples that should NOT trigger DL3041:
- `RUN dnf install -y tomcat-9.0.1 && dnf clean all`
- `RUN microdnf install -y tomcat-9.0.1 && microdnf clean all`
- `RUN dnf module install -y tomcat:9 && dnf clean all`
- `RUN microdnf module install -y tomcat:9 && microdnf clean all`
- Commands for other binaries (e.g. `notdnf`) must not be matched.

Reproduction summary:
Using a Dockerfile like:

```Dockerfile
FROM registry.access.redhat.com/ubi7/ubi-minimal:7.9

RUN microdnf install rh-python38
```

Hadolint currently produces no warnings for the non-ideal `microdnf` invocation. After the fix, the same `microdnf` patterns should be detected and reported under DL3038/DL3040/DL3041 just like their `dnf` equivalents.

Note: The rule messages may still mention `dnf` in their wording; the critical requirement is that `microdnf` usage triggers (or does not trigger) the same rules under the same conditions as `dnf`.