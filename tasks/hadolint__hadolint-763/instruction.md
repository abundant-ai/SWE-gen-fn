hadolint currently allows invalid Dockerfiles where instructions that require an initialized build stage (e.g., LABEL, RUN, etc.) appear before the first FROM. This is incorrect because Dockerfiles must begin a build stage with a FROM instruction; the only valid lines allowed before the first FROM are comment lines and (optionally) ARG instructions.

As a result, hadolint exits successfully for Dockerfiles that Docker considers invalid or that will fail to build. For example, linting this input should report an error, but currently does not:

```Dockerfile
LABEL maintainer="ye@example.com"
FROM python:3.9-slim-bullseye

ARG DEBIAN_FRONTEND=noninteractive
```

Another example that should be flagged:

```Dockerfile
RUN echo "bad"
FROM alpine:3
RUN echo "ok"
```

Add a new rule named DL3061 that detects invalid instruction order at the beginning of a Dockerfile. DL3061 should trigger when the first non-comment instruction is not FROM or ARG, or when any instruction other than comment/ARG appears before the first FROM.

Expected behavior:
- DL3061 is reported for Dockerfiles that begin with an instruction like LABEL (or RUN, COPY, etc.) before the first FROM.
- DL3061 is not reported when the Dockerfile begins with one or more comment lines and/or ARG instructions followed by a FROM.
- DL3061 is not reported for valid sequences such as:

```Dockerfile
FROM foo
LABEL foo=bar
```

and:

```Dockerfile
ARG A=B
FROM foo
LABEL foo=bar
```

and:

```Dockerfile
FROM foo
ARG A=B
RUN echo bla
```

The rule must be enforced consistently in both the regular linting flow and the build-context linting flow (i.e., both entry points that can evaluate a Dockerfile should emit DL3061 for the same invalid inputs). Also ensure existing behavior remains correct for Dockerfiles that start with a FROM and then proceed with other instructions, and that comment lines (including comments containing trailing backslashes) are treated as comments and do not affect whether DL3061 triggers.