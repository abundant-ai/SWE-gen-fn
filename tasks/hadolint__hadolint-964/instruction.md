Hadolint currently emits rule DL3005 to discourage running package upgrades/updates (e.g., `apt-get upgrade`, `yum update`) in Dockerfiles. This guidance is considered incorrect for many real-world images because base images are often not rebuilt immediately after upstream security fixes land, so omitting upgrades can leave containers missing critical security updates for days or months.

The problem is that DL3005 still exists and will flag Dockerfiles that intentionally run package upgrades to pull in security fixes. Hadolint should stop warning/erroring about this pattern.

Update hadolint so that DL3005 is removed entirely:

- Hadolint must no longer report DL3005 under any circumstances.
- Any configuration that references DL3005 (for example, ignoring it or setting its severity) should no longer cause failures due to an “unknown rule” style error; it should behave as if the rule does not exist.
- Any built-in rule listings/help output/metadata should no longer include DL3005.

Example behavior change:

- A Dockerfile containing a command like `RUN apt-get update && apt-get upgrade -y` (or equivalent `yum update -y`, etc.) should not produce a DL3005 finding.

This change is intended to address the complaint that “security updates should be in most Dockerfiles” and that discouraging upgrades leads to outdated packages when base images lag behind upstream security releases.