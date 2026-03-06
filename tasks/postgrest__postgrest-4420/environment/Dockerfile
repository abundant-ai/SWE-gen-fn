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
# The fix changes `dumpQi` to `quoteQi` in AppState.hs and adds quoteQi function
# No need to build PostgREST - test checks code changes in Haskell files

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin 3ddb343aa58c2c171b915e5ded4d48e646e9bcd5 || git fetch --depth 1 origin "+refs/pull/4420/head:refs/remotes/origin/pr/4420") && \
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
