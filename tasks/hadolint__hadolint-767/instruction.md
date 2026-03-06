DL3026 ("Use only an allowed registry in the FROM image") currently only supports exact registry matches via the configuration option for allowed/trusted registries (e.g., `allowedRegistries` / `--trusted-registry`). This makes it impractical for private registry setups (such as Artifactory) where registries are created as subdomains (e.g., `repo-name.artifactory-url.com`) and new subdomains appear frequently.

Add support for wildcard domains in the allowed/trusted registry configuration so users can configure patterns like:

```yaml
trustedRegistries:
  - *.artifactory-url.com
```

or via CLI:

```bash
hadolint --trusted-registry "*.megacorp.com" Dockerfile
```

Expected behavior:

- When `allowedRegistries` is empty, DL3026 must not warn for any `FROM` registry.
- With `allowedRegistries = ["docker.io"]`, the rule must treat both the implicit Docker Hub form (`FROM ubuntu:18.04` and `FROM namespace/image:tag`) and the explicit form (`FROM docker.io/namespace/image:tag`) as allowed.
- `FROM scratch` must never trigger DL3026.
- `FROM <previous-stage>` (multi-stage build stage references) must not trigger DL3026.
- Wildcards must be supported in `allowedRegistries` entries:
  - A leading `*.` entry like `*.random.com` must allow any subdomain of `random.com` such as `foo.random.com`, and must not allow a different domain like `x.com`.
  - A single `"*"` entry must allow any registry (effectively disabling registry restriction).

Actual behavior to fix:

- With `allowedRegistries` configured to include wildcard domains (e.g., `*.random.com`), DL3026 currently still warns on images that should be allowed, because matching is performed as exact string equality rather than supporting wildcard patterns.

Implement wildcard-aware matching in the registry-allow check used by DL3026 (e.g., the function responsible for determining if a registry is allowed, such as `isAllowed`), so that wildcard entries work as described above while preserving existing exact-match behavior.