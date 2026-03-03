Hadolint incorrectly reports that RPM packages installed via `dnf`/`microdnf`/`yum` are not version-pinned when the version includes an RPM epoch (an integer followed by a colon, e.g. `1:1.1.1k`). This started showing up as false positives for rule DL3041 ("Specify version with `dnf install -y <package>-<version>`") and also needs to be handled for the analogous yum rule DL3033 ("Specify version with `yum install -y <package>-<version>`").

Reproduction example that should NOT trigger DL3041:
```dockerfile
RUN dnf install --assumeyes \
    jq-1.6 \
    openssl-1:1.1.1k \
    findutils-1:4.6.0 \
    bc-1.07.1 \
    && dnf clean all
```
Currently, `openssl-1:1.1.1k` is treated as if it were not properly pinned, causing DL3041 to be emitted.

Update the parsing/validation used by DL3041 and DL3033 so that a package argument of the form:
- `<name>-<version>` is considered pinned, and
- `<version>` may include an epoch prefix `<epoch>:<version>` (where `<epoch>` is an integer and the colon is part of the version spec).

The following behaviors must hold:
- For `dnf install -y` and `microdnf install -y`, DL3041 should NOT be emitted when a package is pinned with an epoch version like `openssl-1:1.1.1k`.
- For `yum install -y`, DL3033 should NOT be emitted when a package is pinned with an epoch version like `openssl-1:1.1.1k`.
- Unpinned installs must still be flagged (e.g., `RUN dnf install -y tomcat && dnf clean all` should still emit DL3041; `RUN yum install -y tomcat && yum clean all` should still emit DL3033).
- The existing behavior for package names containing hyphens must remain correct (e.g., `rpm-sign-4.16.1.3` is pinned and should not be flagged).
- Commands that are not the relevant package manager binaries must not be affected (e.g., `RUN notdnf install openssl-1:1.1.1k` should not trigger DL3041).
- Module installs should continue to be handled as before (e.g., `dnf module install -y tomcat:9` is a valid pinned module stream and should not be flagged, while `dnf module install -y tomcat` should be flagged).