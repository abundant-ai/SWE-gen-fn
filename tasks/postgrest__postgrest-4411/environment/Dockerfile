FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# This is a Haskell project, but we only need to verify the code changes
# The fix changes Config.hs to have three separate internal schema cache sleep configs
# and SchemaCache.hs to apply them at different loading stages
# No need to build PostgREST - test checks code changes in Haskell files

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin 3dde9b3f33aeeb61c6dc444fbf0a91afc281da0f || git fetch --depth 1 origin "+refs/pull/4411/head:refs/remotes/origin/pr/4411") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
