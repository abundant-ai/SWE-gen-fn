DL3009 (“Delete the apt-get lists after installing something”) incorrectly reports a violation for Dockerfiles that use BuildKit cache mounts on apt directories via a RUN instruction with multiple `--mount` flags.

When a Dockerfile uses BuildKit syntax (e.g. `# syntax = docker/dockerfile:1.3`) and runs apt commands under a `RUN` instruction that includes more than one `--mount=type=cache,...` option, hadolint should treat the mounted apt directories as cached and avoid requiring `rm -rf /var/lib/apt/lists/*` cleanup for that RUN.

Currently, a RUN like the following triggers DL3009 even though it should not:

```Dockerfile
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get --no-install-recommends install -y gcc=4:9.3.0-1ubuntu2
```

Observed behavior: hadolint emits something like:

`DL3009 info: Delete the apt-get lists after installing something`

Expected behavior: DL3009 must be suppressed when the RUN instruction uses one or more cache mounts whose `target` covers apt list/cache locations (notably `/var/lib/apt/lists` and related apt directories). This must work when there are multiple `--mount` flags in the same RUN instruction (not just a single mount).

The fix should ensure the RUN instruction parser/representation preserves all `--mount` options, and the DL3009 rule evaluates all mounts on that RUN when deciding whether apt list cleanup is required. The result should be that DL3009 continues to fire for ordinary `apt-get update && apt-get install ...` without cleanup, but does not fire when BuildKit cache mounts are used to persist the relevant apt directories across layers.