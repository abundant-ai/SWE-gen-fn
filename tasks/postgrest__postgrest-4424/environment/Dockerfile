FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# This is a Haskell project, but the test verifies dependency version changes
# The fix upgrades configurator-pg dependency which enables UTF-8 config file support
# No need to build PostgREST - test checks dependency version in config files

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin 682e18cab0a08d61613dbac1bc2867ab3e814ed4 || git fetch --depth 1 origin "+refs/pull/4424/head:refs/remotes/origin/pr/4424") && \
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
