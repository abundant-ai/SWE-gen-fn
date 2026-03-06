FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# This is a Haskell project, but we only need to verify dependency version changes
# The fix upgrades configurator-pg from 0.2 to 0.2.11 to support UTF-8 config files
# and adds UTF-8 config test files
# No need to build PostgREST - test checks dependency versions and file existence

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin 2c5e75ccacc5783830597a84533cfa7a3bb08a55 || git fetch --depth 1 origin "+refs/pull/4398/head:refs/remotes/origin/pr/4398") && \
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
