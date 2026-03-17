FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# PostgREST is a Haskell project, but we don't need to build it for verification
# We only need to check if the fix was applied correctly

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin 3425ae46f3d8720feb3cbc23261a90aec559dcbd || git fetch --depth 1 origin "+refs/pull/2133/head:refs/remotes/origin/pr/2133") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV CI=true

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# No rebuild needed - we're only verifying the fix was applied

RUN rm -rf /app/src/.git

WORKDIR /app/src
